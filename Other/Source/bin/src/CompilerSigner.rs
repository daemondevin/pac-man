// Code Signing Utility with Certificate Support
// Signs programs and verifies signatures using RSA cryptography with X.509 certificates
//

use base64::{engine::general_purpose, Engine as _};
use chrono::{Duration, Utc};
use clap::{Parser, Subcommand};
use der::{Decode, Encode};
use rsa::{
    pkcs8::{DecodePrivateKey, DecodePublicKey, EncodePrivateKey, EncodePublicKey, LineEnding},
    RsaPrivateKey, RsaPublicKey,
    signature::{RandomizedSigner, SignatureEncoding, Verifier},
    pss::{BlindedSigningKey, Signature, VerifyingKey},
};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use spki::SubjectPublicKeyInfoOwned;
use std::{
    fs,
    path::{Path, PathBuf},
    process,
    str::FromStr,
};
use x509_cert::{
    builder::{Builder, CertificateBuilder, Profile},
    name::Name,
    serial_number::SerialNumber,
    time::Validity,
    Certificate,
};

#[derive(Parser)]
#[command(name = "CompilerSigner")]
#[command(about = "Code Signing Utility with Certificate Support", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    #[arg(long, default_value = ".keys", global = true)]
    key_dir: PathBuf,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate a new RSA key pair
    GenerateKeys {
        #[arg(long, default_value_t = 2048)]
        bits: usize,
    },
    /// Generate a self-signed certificate for code signing
    GenerateCert {
        /// Common Name (e.g., "Your Name" or "Your Company")
        #[arg(long)]
        cn: String,
        /// Organization
        #[arg(long)]
        org: Option<String>,
        /// Country (2-letter code)
        #[arg(long)]
        country: Option<String>,
        /// Days until expiration
        #[arg(long, default_value_t = 365)]
        days: i64,
        /// Output format: pem, der, or pfx
        #[arg(long, default_value = "pem")]
        format: String,
        /// Password for PFX format (required if format is pfx)
        #[arg(long)]
        password: Option<String>,
    },
    /// Sign a file with certificate
    Sign {
        /// File to sign
        file: PathBuf,
        /// Use certificate-based signing
        #[arg(long)]
        with_cert: bool,
    },
    /// Verify a file signature
    Verify {
        /// File to verify
        file: PathBuf,
    },
    /// Show certificate information
    ShowCert {
        /// Certificate file path (optional, defaults to certificate.pem in key directory)
        #[arg(long)]
        cert: Option<PathBuf>,
    },
    /// Export certificate to different format
    ExportCert {
        /// Output format: pem, der, cer, or pfx
        #[arg(long)]
        format: String,
        /// Output file path
        #[arg(long)]
        output: PathBuf,
        /// Password for PFX format (required if format is pfx)
        #[arg(long)]
        password: Option<String>,
    },
}

#[derive(Serialize, Deserialize)]
struct SignatureData {
    file: String,
    size: u64,
    sha256: String,
    signature: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    certificate: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    cert_subject: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    cert_issuer: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    cert_valid_from: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    cert_valid_to: Option<String>,
}

struct CodeSigner {
    key_dir: PathBuf,
    private_key_path: PathBuf,
    public_key_path: PathBuf,
    cert_path: PathBuf,
}

impl CodeSigner {
    fn new(key_dir: PathBuf) -> Self {
        let private_key_path = key_dir.join("private_key.pem");
        let public_key_path = key_dir.join("public_key.pem");
        let cert_path = key_dir.join("certificate.pem");

        Self {
            key_dir,
            private_key_path,
            public_key_path,
            cert_path,
        }
    }

    fn generate_keys(&self, bits: usize) -> Result<(), Box<dyn std::error::Error>> {
        println!("Generating {}-bit RSA key pair...", bits);

        fs::create_dir_all(&self.key_dir)?;

        let mut rng = rand::thread_rng();
        let private_key = RsaPrivateKey::new(&mut rng, bits)?;
        let public_key = RsaPublicKey::from(&private_key);

        // Save private key
        private_key.write_pkcs8_pem_file(&self.private_key_path, LineEnding::LF)?;

        // Save public key
        public_key.write_public_key_pem_file(&self.public_key_path, LineEnding::LF)?;

        println!("Keys generated successfully");
        println!("  Private key: {}", self.private_key_path.display());
        println!("  Public key: {}", self.public_key_path.display());

        Ok(())
    }

    fn generate_certificate(
        &self,
        cn: &str,
        org: Option<&str>,
        country: Option<&str>,
        days: i64,
        format: &str,
        password: Option<&str>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        if !self.private_key_path.exists() {
            eprintln!("Error: Private key not found. Generate keys first with: generate-keys");
            process::exit(1);
        }

        println!("Generating self-signed certificate...");

        let private_key = self.load_private_key()?;
        let public_key = RsaPublicKey::from(&private_key);

        // Build subject/issuer name
        let mut subject_parts = vec![format!("CN={}", cn)];
        if let Some(o) = org {
            subject_parts.push(format!("O={}", o));
        }
        if let Some(c) = country {
            subject_parts.push(format!("C={}", c));
        }
        let subject_str = subject_parts.join(",");
        let subject = Name::from_str(&subject_str)?;

        // Generate serial number
        let serial_num: u64 = rand::random();
        let serial = SerialNumber::from(serial_num);

        // Set validity period
        let not_before = Utc::now();
        let not_after = not_before + Duration::days(days);
        let validity = Validity::from_now(std::time::Duration::from_secs((days * 86400) as u64))?;

        // Convert public key to SPKI
        let spki = SubjectPublicKeyInfoOwned::from_key(public_key)?;

        // Create signing key for certificate generation (using PKCS1v15 which is better supported)
        let signing_key = rsa::pkcs1v15::SigningKey::<Sha256>::new(private_key);

        // Build certificate
        let builder = CertificateBuilder::new(
            Profile::Root,
            serial,
            validity,
            subject.clone(),
            spki,
            &signing_key,
        )?;

        let cert = builder.build::<rsa::pkcs1v15::Signature>()?;

        // Save certificate in PEM format
        let cert_der = cert.to_der()?;
        let cert_pem = format!(
            "-----BEGIN CERTIFICATE-----\n{}\n-----END CERTIFICATE-----\n",
            general_purpose::STANDARD.encode(&cert_der)
        );
        fs::write(&self.cert_path, cert_pem)?;

        println!("Certificate generated successfully");
        println!("  Certificate: {}", self.cert_path.display());
        println!("  Subject: {}", subject_str);
        println!("  Valid from: {}", not_before.format("%Y-%m-%d %H:%M:%S UTC"));
        println!("  Valid to: {}", not_after.format("%Y-%m-%d %H:%M:%S UTC"));

        Ok(())
    }

    fn load_private_key(&self) -> Result<RsaPrivateKey, Box<dyn std::error::Error>> {
        let key = RsaPrivateKey::read_pkcs8_pem_file(&self.private_key_path)?;
        Ok(key)
    }

    fn load_public_key(&self) -> Result<RsaPublicKey, Box<dyn std::error::Error>> {
        let key = RsaPublicKey::read_public_key_pem_file(&self.public_key_path)?;
        Ok(key)
    }

    fn load_certificate(&self) -> Result<Certificate, Box<dyn std::error::Error>> {
        self.load_certificate_from_path(&self.cert_path)
    }

    fn load_certificate_from_path(&self, path: &Path) -> Result<Certificate, Box<dyn std::error::Error>> {
        let file_data = fs::read(path)?;
        
        // Try to detect format
        if file_data.starts_with(b"-----BEGIN CERTIFICATE-----") {
            // PEM format
            let pem_str = String::from_utf8(file_data)?;
            let cert_b64: String = pem_str
                .lines()
                .filter(|line| !line.starts_with("-----"))
                .collect();
            let cert_der = general_purpose::STANDARD.decode(cert_b64)?;
            Ok(Certificate::from_der(&cert_der)?)
        } else {
            // Assume DER/CER format
            Ok(Certificate::from_der(&file_data)?)
        }
    }

    fn sign_file(&self, file_path: &Path, with_cert: bool) -> Result<(), Box<dyn std::error::Error>> {
        if !file_path.exists() {
            eprintln!("Error: File not found: {}", file_path.display());
            process::exit(1);
        }

        if !self.private_key_path.exists() {
            eprintln!("Error: Private key not found. Generate keys first with: generate-keys");
            process::exit(1);
        }

        if with_cert && !self.cert_path.exists() {
            eprintln!("Error: Certificate not found. Generate certificate first with: generate-cert");
            process::exit(1);
        }

        println!("Signing {}...", file_path.display());
        if with_cert {
            println!("  Using certificate-based signing");
        }

        // Read file and compute hash
        let file_data = fs::read(file_path)?;
        let mut hasher = Sha256::new();
        hasher.update(&file_data);
        let file_hash = hasher.finalize();

        // Sign the hash
        let private_key = self.load_private_key()?;
        let signing_key = BlindedSigningKey::<Sha256>::new(private_key);
        let mut rng = rand::thread_rng();
        let signature = signing_key.sign_with_rng(&mut rng, &file_hash);

        // Create signature data
        let mut sig_data = SignatureData {
            file: file_path
                .file_name()
                .unwrap()
                .to_string_lossy()
                .to_string(),
            size: file_data.len() as u64,
            sha256: general_purpose::STANDARD.encode(&file_hash[..]),
            signature: general_purpose::STANDARD.encode(signature.to_bytes()),
            certificate: None,
            cert_subject: None,
            cert_issuer: None,
            cert_valid_from: None,
            cert_valid_to: None,
        };

        // Add certificate info if requested
        if with_cert {
            let cert = self.load_certificate()?;
            let cert_der = cert.to_der()?;
            sig_data.certificate = Some(general_purpose::STANDARD.encode(&cert_der));
            sig_data.cert_subject = Some(cert.tbs_certificate.subject.to_string());
            sig_data.cert_issuer = Some(cert.tbs_certificate.issuer.to_string());
            sig_data.cert_valid_from = Some(cert.tbs_certificate.validity.not_before.to_string());
            sig_data.cert_valid_to = Some(cert.tbs_certificate.validity.not_after.to_string());
        }

        let sig_path = file_path.with_extension(
            format!(
                "{}.sig",
                file_path.extension().unwrap_or_default().to_string_lossy()
            )
        );

        let sig_json = serde_json::to_string_pretty(&sig_data)?;
        fs::write(&sig_path, sig_json)?;

        println!("Signature created: {}", sig_path.display());

        Ok(())
    }

    fn verify_file(&self, file_path: &Path) -> Result<bool, Box<dyn std::error::Error>> {
        let sig_path = file_path.with_extension(
            format!(
                "{}.sig",
                file_path.extension().unwrap_or_default().to_string_lossy()
            )
        );

        if !file_path.exists() {
            eprintln!("Error: File not found: {}", file_path.display());
            return Ok(false);
        }

        if !sig_path.exists() {
            eprintln!("Error: Signature file not found: {}", sig_path.display());
            return Ok(false);
        }

        println!("Verifying {}...", file_path.display());

        // Load signature data
        let sig_json = fs::read_to_string(&sig_path)?;
        let sig_data: SignatureData = serde_json::from_str(&sig_json)?;

        // Read and hash file
        let file_data = fs::read(file_path)?;
        let mut hasher = Sha256::new();
        hasher.update(&file_data);
        let file_hash = hasher.finalize();

        // Check file hash matches
        let expected_hash = general_purpose::STANDARD.decode(&sig_data.sha256)?;
        if &file_hash[..] != expected_hash.as_slice() {
            println!("Verification FAILED: File has been modified");
            return Ok(false);
        }

        // Get public key (from certificate if present, otherwise from key file)
        let public_key = if let Some(cert_b64) = &sig_data.certificate {
            println!("  Certificate found in signature");
            let cert_der = general_purpose::STANDARD.decode(cert_b64)?;
            let cert = Certificate::from_der(&cert_der)?;
            
            // Display certificate info
            if let Some(subject) = &sig_data.cert_subject {
                println!("  Signed by: {}", subject);
            }
            if let (Some(from), Some(to)) = (&sig_data.cert_valid_from, &sig_data.cert_valid_to) {
                println!("  Valid: {} to {}", from, to);
            }

            // Extract public key from certificate
            let spki = &cert.tbs_certificate.subject_public_key_info;
            let spki_der = spki.to_der()?;
            RsaPublicKey::from_public_key_der(&spki_der)?
        } else {
            if !self.public_key_path.exists() {
                eprintln!("Error: Public key not found");
                return Ok(false);
            }
            self.load_public_key()?
        };

        // Verify signature
        let verifying_key = VerifyingKey::<Sha256>::new(public_key);
        let signature_bytes = general_purpose::STANDARD.decode(&sig_data.signature)?;
        let signature = Signature::try_from(signature_bytes.as_slice())?;

        match verifying_key.verify(&file_hash, &signature) {
            Ok(_) => {
                println!("Signature is VALID");
                Ok(true)
            }
            Err(_) => {
                println!("Signature verification FAILED");
                Ok(false)
            }
        }
    }

    fn show_certificate(&self, cert_path: Option<&Path>) -> Result<(), Box<dyn std::error::Error>> {
        let path = cert_path.unwrap_or(&self.cert_path);
        
        if !path.exists() {
            eprintln!("Error: Certificate not found at {}", path.display());
            eprintln!("Generate one with: generate-cert --cn \"Your Name\"");
            process::exit(1);
        }

        let cert = self.load_certificate_from_path(path)?;
        
        println!("Certificate Information:");
        println!("  Subject: {}", cert.tbs_certificate.subject);
        println!("  Issuer: {}", cert.tbs_certificate.issuer);
        println!("  Serial: {:?}", cert.tbs_certificate.serial_number);
        println!("  Valid From: {}", cert.tbs_certificate.validity.not_before);
        println!("  Valid To: {}", cert.tbs_certificate.validity.not_after);
        println!("  Location: {}", path.display());

        Ok(())
    }

    fn export_certificate(
        &self,
        format: &str,
        output: &Path,
        password: Option<&str>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        if !self.cert_path.exists() {
            eprintln!("Error: Certificate not found. Generate one first with: generate-cert");
            process::exit(1);
        }

        let cert = self.load_certificate()?;
        let cert_der = cert.to_der()?;

        match format.to_lowercase().as_str() {
            "pem" => {
                let cert_pem = format!(
                    "-----BEGIN CERTIFICATE-----\n{}\n-----END CERTIFICATE-----\n",
                    general_purpose::STANDARD.encode(&cert_der)
                );
                fs::write(output, cert_pem)?;
                println!("Certificate exported to {} (PEM format)", output.display());
            }
            "der" | "cer" => {
                fs::write(output, cert_der)?;
                println!("Certificate exported to {} (DER/CER format)", output.display());
            }
            "pfx" | "p12" => {
                if password.is_none() {
                    eprintln!("Error: Password required for PFX format. Use --password <password>");
                    process::exit(1);
                }
                eprintln!("Note: PFX/P12 export requires additional dependencies.");
                eprintln!("Use OpenSSL to create PFX:");
                eprintln!("  openssl pkcs12 -export -out {} -inkey {} -in {} -passout pass:{}",
                    output.display(),
                    self.private_key_path.display(),
                    self.cert_path.display(),
                    password.unwrap_or("your_password")
                );
            }
            _ => {
                eprintln!("Error: Unsupported format '{}'. Use: pem, der, cer, or pfx", format);
                process::exit(1);
            }
        }

        Ok(())
    }
}

fn main() {
    let cli = Cli::parse();
    let signer = CodeSigner::new(cli.key_dir);

    let result = match cli.command {
        Commands::GenerateKeys { bits } => signer.generate_keys(bits),
        Commands::GenerateCert { cn, org, country, days, format, password } => {
            signer.generate_certificate(&cn, org.as_deref(), country.as_deref(), days, &format, password.as_deref())
        }
        Commands::Sign { file, with_cert } => signer.sign_file(&file, with_cert),
        Commands::Verify { file } => signer.verify_file(&file).map(|_| ()),
        Commands::ShowCert { cert } => signer.show_certificate(cert.as_deref()),
        Commands::ExportCert { format, output, password } => {
            signer.export_certificate(&format, &output, password.as_deref())
        }
    };

    if let Err(e) = result {
        eprintln!("Error: {}", e);
        process::exit(1);
    }
}