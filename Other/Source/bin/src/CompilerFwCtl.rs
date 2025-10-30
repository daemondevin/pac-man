use clap::{Parser, Subcommand, ValueEnum};
use std::fmt;

#[cfg(windows)]
use windows::{
    core::*,
    Win32::System::Com::*,
    Win32::NetworkManagement::WindowsFirewall::*,
    Win32::Foundation::*,
};

#[derive(Parser)]
#[command(name = "CompilerFwCtl")]
#[command(about = "A firewall control utility", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Add a new firewall rule
    Add {
        /// Name of the rule
        #[arg(short, long)]
        name: String,

        /// Direction of the rule
        #[arg(short, long, value_enum)]
        dir: Direction,

        /// Action to take
        #[arg(short, long, value_enum)]
        action: Action,

        /// Protocol
        #[arg(short, long, default_value = "any")]
        protocol: String,

        /// Local port
        #[arg(long)]
        localport: Option<String>,

        /// Remote port
        #[arg(long)]
        remoteport: Option<String>,

        /// Local address
        #[arg(long)]
        localip: Option<String>,

        /// Remote address
        #[arg(long)]
        remoteip: Option<String>,

        /// Program path
        #[arg(long)]
        program: Option<String>,

        /// Service name
        #[arg(long)]
        service: Option<String>,

        /// Profile (domain, private, public, or any)
        #[arg(long, default_value = "any")]
        profile: String,

        /// Enable the rule
        #[arg(long, value_enum, default_value = "yes")]
        enable: EnableOption,

        /// Description
        #[arg(long)]
        description: Option<String>,
    },

    /// Delete firewall rule(s)
    Delete {
        /// Name of the rule to delete
        #[arg(short, long)]
        name: String,
    },

    /// Set firewall rule properties
    Set {
        /// Name of the rule to modify
        #[arg(short, long)]
        name: String,

        /// New action
        #[arg(short, long, value_enum)]
        action: Option<Action>,

        /// Enable/disable the rule
        #[arg(long, value_enum)]
        enable: Option<EnableOption>,

        /// New profile
        #[arg(long)]
        profile: Option<String>,
    },

    /// Show firewall rules
    Show {
        /// Show all rules or filter by name
        #[arg(short, long)]
        name: Option<String>,

        /// Verbose output
        #[arg(short, long)]
        verbose: bool,
    },

    /// Reset firewall to default settings
    Reset,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum, Debug)]
enum Direction {
    In,
    Out,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum, Debug)]
enum Action {
    Allow,
    Block,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum EnableOption {
    Yes,
    No,
}

impl fmt::Display for Direction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Direction::In => write!(f, "Inbound"),
            Direction::Out => write!(f, "Outbound"),
        }
    }
}

impl fmt::Display for Action {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Action::Allow => write!(f, "Allow"),
            Action::Block => write!(f, "Block"),
        }
    }
}

impl fmt::Display for EnableOption {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            EnableOption::Yes => write!(f, "Yes"),
            EnableOption::No => write!(f, "No"),
        }
    }
}

#[derive(Debug, Clone)]
struct FirewallRule {
    name: String,
    direction: Direction,
    action: Action,
    protocol: String,
    localport: Option<String>,
    remoteport: Option<String>,
    localip: Option<String>,
    remoteip: Option<String>,
    program: Option<String>,
    service: Option<String>,
    profile: String,
    enabled: bool,
    description: Option<String>,
}

impl fmt::Display for FirewallRule {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "Rule Name:            {}\n\
             Enabled:              {}\n\
             Direction:            {}\n\
             Action:               {}\n\
             Protocol:             {}\n\
             Local Port:           {}\n\
             Remote Port:          {}\n\
             Local IP:             {}\n\
             Remote IP:            {}\n\
             Program:              {}\n\
             Service:              {}\n\
             Profile:              {}\n\
             Description:          {}",
            self.name,
            if self.enabled { "Yes" } else { "No" },
            self.direction,
            self.action,
            self.protocol,
            self.localport.as_deref().unwrap_or("Any"),
            self.remoteport.as_deref().unwrap_or("Any"),
            self.localip.as_deref().unwrap_or("Any"),
            self.remoteip.as_deref().unwrap_or("Any"),
            self.program.as_deref().unwrap_or("Any"),
            self.service.as_deref().unwrap_or("Any"),
            self.profile,
            self.description.as_deref().unwrap_or("")
        )
    }
}

// Custom error type to avoid conflicts with windows::core::Result
type StdResult<T> = std::result::Result<T, Box<dyn std::error::Error>>;

// Windows-specific firewall backend
#[cfg(windows)]
struct WindowsFirewallBackend {
    policy: INetFwPolicy2,
}

#[cfg(windows)]
impl WindowsFirewallBackend {
    fn new() -> StdResult<Self> {
        unsafe {
            CoInitializeEx(None, COINIT_MULTITHREADED).ok()?;
            
            let policy: INetFwPolicy2 = CoCreateInstance(
                &NetFwPolicy2,
                None,
                CLSCTX_ALL,
            )?;

            Ok(WindowsFirewallBackend { policy })
        }
    }

    fn add_rule(&self, rule: FirewallRule) -> StdResult<()> {
        unsafe {
            let fw_rule: INetFwRule = CoCreateInstance(
                &NetFwRule,
                None,
                CLSCTX_ALL,
            )?;

            // Set rule name
            fw_rule.SetName(&BSTR::from(rule.name.as_str()))?;

            // Set description if provided
            if let Some(desc) = &rule.description {
                fw_rule.SetDescription(&BSTR::from(desc.as_str()))?;
            }

            // Set direction
            let direction = match rule.direction {
                Direction::In => NET_FW_RULE_DIR_IN,
                Direction::Out => NET_FW_RULE_DIR_OUT,
            };
            fw_rule.SetDirection(direction)?;

            // Set action
            let action = match rule.action {
                Action::Allow => NET_FW_ACTION_ALLOW,
                Action::Block => NET_FW_ACTION_BLOCK,
            };
            fw_rule.SetAction(action)?;

            // Set protocol
            let protocol_num = match rule.protocol.to_lowercase().as_str() {
                "tcp" => 6,
                "udp" => 17,
                "icmpv4" => 1,
                "icmpv6" => 58,
                "any" => 256,
                num => num.parse::<i32>().unwrap_or(256),
            };
            fw_rule.SetProtocol(protocol_num)?;

            // Set local ports
            if let Some(port) = &rule.localport {
                fw_rule.SetLocalPorts(&BSTR::from(port.as_str()))?;
            }

            // Set remote ports
            if let Some(port) = &rule.remoteport {
                fw_rule.SetRemotePorts(&BSTR::from(port.as_str()))?;
            }

            // Set local addresses
            if let Some(addr) = &rule.localip {
                fw_rule.SetLocalAddresses(&BSTR::from(addr.as_str()))?;
            }

            // Set remote addresses
            if let Some(addr) = &rule.remoteip {
                fw_rule.SetRemoteAddresses(&BSTR::from(addr.as_str()))?;
            }

            // Set application path
            if let Some(app) = &rule.program {
                fw_rule.SetApplicationName(&BSTR::from(app.as_str()))?;
            }

            // Set service name
            if let Some(svc) = &rule.service {
                fw_rule.SetServiceName(&BSTR::from(svc.as_str()))?;
            }

            // Set profile
            let profile_type = match rule.profile.to_lowercase().as_str() {
                "domain" => NET_FW_PROFILE2_DOMAIN.0,
                "private" => NET_FW_PROFILE2_PRIVATE.0,
                "public" => NET_FW_PROFILE2_PUBLIC.0,
                "any" | _ => NET_FW_PROFILE2_ALL.0,
            };
            fw_rule.SetProfiles(profile_type)?;

            // Enable/disable rule - convert bool to VARIANT_BOOL
            let enabled = if rule.enabled { VARIANT_TRUE } else { VARIANT_FALSE };
            fw_rule.SetEnabled(enabled)?;

            // Add rule to policy
            let rules = self.policy.Rules()?;
            rules.Add(&fw_rule)?;

            println!("Ok.");
            println!("Added rule: {}", rule.name);
            Ok(())
        }
    }

    fn delete_rule(&self, name: &str) -> StdResult<()> {
        unsafe {
            let rules = self.policy.Rules()?;
            rules.Remove(&BSTR::from(name))?;
            
            println!("Ok.");
            println!("Deleted rule: {}", name);
            Ok(())
        }
    }

    fn set_rule(&self, name: &str, action: Option<Action>, enable: Option<EnableOption>, profile: Option<String>) -> StdResult<()> {
        unsafe {
            let rules = self.policy.Rules()?;
            let rule = rules.Item(&BSTR::from(name))?;

            if let Some(a) = action {
                let fw_action = match a {
                    Action::Allow => NET_FW_ACTION_ALLOW,
                    Action::Block => NET_FW_ACTION_BLOCK,
                };
                rule.SetAction(fw_action)?;
            }

            if let Some(e) = enable {
                let enabled = if matches!(e, EnableOption::Yes) { VARIANT_TRUE } else { VARIANT_FALSE };
                rule.SetEnabled(enabled)?;
            }

            if let Some(p) = profile {
                let profile_type = match p.to_lowercase().as_str() {
                    "domain" => NET_FW_PROFILE2_DOMAIN.0,
                    "private" => NET_FW_PROFILE2_PRIVATE.0,
                    "public" => NET_FW_PROFILE2_PUBLIC.0,
                    "any" | _ => NET_FW_PROFILE2_ALL.0,
                };
                rule.SetProfiles(profile_type)?;
            }

            println!("Ok.");
            println!("Updated rule: {}", name);
            Ok(())
        }
    }

    fn show_rules(&self, name: Option<&str>, verbose: bool) -> StdResult<()> {
        unsafe {
            let rules = self.policy.Rules()?;
            let count = rules.Count()?;
            
            let mut found_any = false;

            for i in 1..=count {
                let rule = rules.Item(&BSTR::from(i.to_string()))?;
                let rule_name = rule.Name()?.to_string();
                
                // Filter by name if specified
                if let Some(filter_name) = name {
                    if rule_name != filter_name {
                        continue;
                    }
                }

                found_any = true;

                if verbose {
                    let enabled = rule.Enabled()? == VARIANT_TRUE;
                    let direction = match rule.Direction()? {
                        NET_FW_RULE_DIR_IN => "Inbound",
                        NET_FW_RULE_DIR_OUT => "Outbound",
                        _ => "Unknown",
                    };
                    let action = match rule.Action()? {
                        NET_FW_ACTION_ALLOW => "Allow",
                        NET_FW_ACTION_BLOCK => "Block",
                        _ => "Unknown",
                    };
                    
                    let protocol_num = rule.Protocol()?;
                    let protocol = match protocol_num {
                        6 => "TCP".to_string(),
                        17 => "UDP".to_string(),
                        1 => "ICMPv4".to_string(),
                        58 => "ICMPv6".to_string(),
                        256 => "Any".to_string(),
                        _ => protocol_num.to_string(),
                    };

                    let local_ports = rule.LocalPorts().map(|b| b.to_string()).unwrap_or_else(|_| "Any".to_string());
                    let remote_ports = rule.RemotePorts().map(|b| b.to_string()).unwrap_or_else(|_| "Any".to_string());
                    let local_addrs = rule.LocalAddresses().map(|b| b.to_string()).unwrap_or_else(|_| "Any".to_string());
                    let remote_addrs = rule.RemoteAddresses().map(|b| b.to_string()).unwrap_or_else(|_| "Any".to_string());
                    let app_name = rule.ApplicationName().map(|b| b.to_string()).unwrap_or_else(|_| "Any".to_string());
                    let service_name = rule.ServiceName().map(|b| b.to_string()).unwrap_or_else(|_| "Any".to_string());
                    let description = rule.Description().map(|b| b.to_string()).unwrap_or_else(|_| "".to_string());

                    let profiles = rule.Profiles()?;
                    let profile_str = match profiles {
                        p if p == NET_FW_PROFILE2_ALL.0 => "All",
                        p if p == NET_FW_PROFILE2_DOMAIN.0 => "Domain",
                        p if p == NET_FW_PROFILE2_PRIVATE.0 => "Private",
                        p if p == NET_FW_PROFILE2_PUBLIC.0 => "Public",
                        _ => "Custom",
                    };

                    println!("Rule Name:            {}", rule_name);
                    println!("Enabled:              {}", if enabled { "Yes" } else { "No" });
                    println!("Direction:            {}", direction);
                    println!("Action:               {}", action);
                    println!("Protocol:             {}", protocol);
                    println!("Local Port:           {}", local_ports);
                    println!("Remote Port:          {}", remote_ports);
                    println!("Local IP:             {}", local_addrs);
                    println!("Remote IP:            {}", remote_addrs);
                    println!("Program:              {}", app_name);
                    println!("Service:              {}", service_name);
                    println!("Profile:              {}", profile_str);
                    println!("Description:          {}", description);
                    println!();
                } else {
                    let enabled = rule.Enabled()? == VARIANT_TRUE;
                    let direction = match rule.Direction()? {
                        NET_FW_RULE_DIR_IN => "In",
                        NET_FW_RULE_DIR_OUT => "Out",
                        _ => "?",
                    };
                    let action = match rule.Action()? {
                        NET_FW_ACTION_ALLOW => "Allow",
                        NET_FW_ACTION_BLOCK => "Block",
                        _ => "?",
                    };

                    println!("{:<50} {:<10} {:<10} {:<10}", 
                        if rule_name.len() > 50 { format!("{}...", &rule_name[..47]) } else { rule_name },
                        direction,
                        action,
                        if enabled { "Yes" } else { "No" }
                    );
                }
            }

            if !found_any {
                println!("No rules match the specified criteria.");
            }

            Ok(())
        }
    }

    fn reset(&self) -> StdResult<()> {
        unsafe {
            self.policy.RestoreLocalFirewallDefaults()?;
            println!("Ok.");
            println!("Firewall rules reset to default.");
            Ok(())
        }
    }
}

#[cfg(windows)]
impl Drop for WindowsFirewallBackend {
    fn drop(&mut self) {
        unsafe {
            CoUninitialize();
        }
    }
}

// Non-Windows stub implementation
#[cfg(not(windows))]
struct WindowsFirewallBackend;

#[cfg(not(windows))]
impl WindowsFirewallBackend {
    fn new() -> StdResult<Self> {
        Err("Windows Firewall API is only available on Windows".into())
    }

    fn add_rule(&self, _rule: FirewallRule) -> StdResult<()> {
        Err("Not implemented on this platform".into())
    }

    fn delete_rule(&self, _name: &str) -> StdResult<()> {
        Err("Not implemented on this platform".into())
    }

    fn set_rule(&self, _name: &str, _action: Option<Action>, _enable: Option<EnableOption>, _profile: Option<String>) -> StdResult<()> {
        Err("Not implemented on this platform".into())
    }

    fn show_rules(&self, _name: Option<&str>, _verbose: bool) -> StdResult<()> {
        Err("Not implemented on this platform".into())
    }

    fn reset(&self) -> StdResult<()> {
        Err("Not implemented on this platform".into())
    }
}

fn main() -> StdResult<()> {
    let cli = Cli::parse();
    let backend = WindowsFirewallBackend::new()?;

    match cli.command {
        Commands::Add {
            name,
            dir,
            action,
            protocol,
            localport,
            remoteport,
            localip,
            remoteip,
            program,
            service,
            profile,
            enable,
            description,
        } => {
            let rule = FirewallRule {
                name,
                direction: dir,
                action,
                protocol,
                localport,
                remoteport,
                localip,
                remoteip,
                program,
                service,
                profile,
                enabled: matches!(enable, EnableOption::Yes),
                description,
            };
            backend.add_rule(rule)?;
        }
        Commands::Delete { name } => {
            backend.delete_rule(&name)?;
        }
        Commands::Set { name, action, enable, profile } => {
            backend.set_rule(&name, action, enable, profile)?;
        }
        Commands::Show { name, verbose } => {
            if !verbose {
                println!("{:<50} {:<10} {:<10} {:<10}", "Name", "Direction", "Action", "Enabled");
                println!("{}", "-".repeat(80));
            }
            backend.show_rules(name.as_deref(), verbose)?;
        }
        Commands::Reset => {
            backend.reset()?;
        }
    }

    Ok(())
}

// ] }