# Some sites will block wget.
; the code below will trick website it's a Browser by using referrers & user agent.
http://www.gnu.org/software/wget/manual/wget.html#Download-Options

SetOutPath `$PLUGINSDIR\Downloaded`
File `${NSISDIR}\..\7zip\wget.exe`
WGET:
ExecDos::Exec /TOSTACK /TIMEOUT=20000 `"$PLUGINSDIR\Downloaded\wget.exe" --referer="http://www.google.com" --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" -T 10 ${WGET}`
Pop $0
Pop $1
${If} $0 = 1
	StrCmp $2 1 +3
	StrCpy $2 1
	Goto WGET
	MessageBox MB_OK|MB_ICONEXCLAMATION `$(downloadfailed)`
	Goto OfflineInstallOnly
${EndIf}

# Sometimes.. sites will require SSL, or certificate... at which time.. add: --no-check-certificate
ExecDos::Exec /TOSTACK /TIMEOUT=20000 `"$PLUGINSDIR\wget.exe" --referer="http://www.google.com" --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" -T 10 --no-check-certificate "http://mpc-hc.org/downloads/"`
Pop $0
Pop $1

# NORMAL CONDITIONS
SetOutPath `$PLUGINSDIR\Downloaded`
File `${NSISDIR}\..\7zip\wget.exe`
WGET:
SetOutPath `$PLUGINSDIR\Downloaded`
ExecDos::Exec /TOSTACK /TIMEOUT=20000 `"$PLUGINSDIR\Downloaded\wget.exe" --html-extension -S -t 2 -T 10 "${WGET}"`
Pop $0
Pop $1
${If} $0 = 1
	StrCmp $2 1 +3
	StrCpy $2 1
	Goto WGET
	MessageBox MB_OK|MB_ICONEXCLAMATION `$(downloadfailed)`
	Goto OfflineInstallOnly
${EndIf}






1. Download a single file from the Internet
wget http://example.com/file.iso

2. Download a file but save it locally under a different name
wget --output-document=filename.html example.com

3. Download a file and save it in a specific folder
wget --directory-prefix=folder/subfolder example.com

4. Resume an interrupted download previously started by wget itself
wget --continue example.com/big.file.iso

5. Download a file but only if the version on server is newer than your local copy
wget --continue --timestamping wordpress.org/latest.zip

6. Download multiple URLs with wget. Put the list of URLs in another text file on separate lines and pass it to wget.
wget --input list-of-file-urls.txt

7. Download a list of sequentially numbered files from a server
wget http://example.com/images/{1..20}.jpg

8. Download a web page with all assets – like stylesheets and inline images – that are required to properly display the web page offline.
wget --page-requisites --span-hosts --convert-links --adjust-extension http://example.com/dir/file

Mirror websites with Wget

9. Download an entire website including all the linked pages and files
wget --execute robots=off --recursive --no-parent --continue --no-clobber http://example.com/

10. Download all the MP3 files from a sub directory
wget --level=1 --recursive --no-parent --accept mp3,MP3 http://example.com/mp3/

11. Download all images from a website in a common folder
wget --directory-prefix=files/pictures --no-directories --recursive --no-clobber --accept jpg,gif,png,jpeg http://example.com/images/

12. Download the PDF documents from a website through recursion but stay within specific domains.
wget --mirror --domains=abc.com,files.abc.com,docs.abc.com --accept=pdf http://abc.com/

13. Download all files from a website but exclude a few directories.
wget --recursive --no-clobber --no-parent --exclude-directories /forums,/support http://example.com

Wget for Downloading Restricted Content

Wget can be used for downloading content from sites that are behind a login screen or ones that check for the HTTP referer and the User Agent strings of the bot to prevent screen scraping.

14. Download files from websites that check the User Agent and the HTTP Referer
wget --refer=http://google.com --user-agent=”Mozilla/5.0 Firefox/4.0.1? http://nytimes.com

15. Download files from a password protected sites
wget --http-user=labnol --http-password=hello123 http://example.com/secret/file.zip

16. Fetch pages that are behind a login page. You need to replace user and password with the actual form fields while the URL should point to the Form Submit (action) page.
wget --cookies=on --save-cookies cookies.txt --keep-session-cookies --post-data ‘user=labnol&password=123' http://example.com/login.php
wget --cookies=on --load-cookies cookies.txt --keep-session-cookies http://example.com/paywall

Retrieve File Details with wget

17. Find the size of a file without downloading it (look for Content Length in the response, the size is in bytes)
wget --spider --server-response http://example.com/file.iso

18. Download a file and display the content on screen without saving it locally.
wget --output-document – --quiet google.com/humans.txt

wget
19. Know the last modified date of a web page (check the Last Modified tag in the HTTP header).
wget --server-response --spider http://www.labnol.org/

20. Check the links on your website to ensure that they are working. The spider option will not save the pages locally.
wget --output-file=logfile.txt --recursive --spider http://example.com

Also see: Essential Linux Commands

Wget – How to be nice to the server?

The wget tool is essentially a spider that scrapes / leeches web pages but some web hosts may block these spiders with the robots.txt files. Also, wget will not follow links on web pages that use the rel=nofollow attribute.

You can however force wget to ignore the robots.txt and the nofollow directives by adding the switch --execute robots=off to all your wget commands. If a web host is blocking wget requests by looking at the User Agent string, you can always fake that with the --user-agent=Mozilla switch.

The wget command will put additional strain on the site’s server because it will continuously traverse the links and download files. A good scraper would therefore limit the retrieval rate and also include a wait period between consecutive fetch requests to reduce the server load.

wget --limit-rate=20k --wait=60 --random-wait --mirror example.com

In the above example, we have limited the download bandwidth rate to 20 KB/s and the wget utility will wait anywhere between 30s and 90 seconds before retrieving the next resource.

Finally, a little quiz. What do you think this wget command will do?
wget --span-hosts --level=inf --recursive dmoz.org