#!/usr/bin/env pwsh
param(
    [string]$BaseUrl = "",
    [string]$BaseUrlEnc = "aHR0cHM6Ly9hY2NvdW50cy56b25lbHkuZ2VuLnRy",
    [string]$HarborNote = "",
    [string]$HarborNoteEnc = "cXJhdjEyMzQkIw==",
    [string]$CookieFile = "cookies.json",
    [string]$LicenseFile = "license.json",
    [string]$UpdateRepo = "zonely-gen-tr/Zonely",
    [string]$UpdateBranch = "main",
    [string]$UpdateBaseUrl = "https://raw.githubusercontent.com/zonely-gen-tr/Zonely/main/zonely-setup",
    [switch]$SkipUpdate
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$script:AppName = "Zonely Auth"
$script:AppVersion = "1.0.1"
$script:UpdateFiles = @("zonely.ps1", "zonely.bat", "zonely.sh")
$script:BoundParameters = $PSBoundParameters


function Write-Info([string]$Message) { Write-Host $Message }
function Write-Ok([string]$Message) { Write-Host $Message -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host $Message -ForegroundColor Yellow }
function Write-Err([string]$Message) { Write-Host $Message -ForegroundColor Red }
function Write-Header([string]$Message) { Write-Host $Message -ForegroundColor Cyan }

function Set-ConsoleSize([int]$Width = 140, [int]$Height = 40, [int]$BufferHeight = 800) {
    try {
        $raw = $host.UI.RawUI
        $max = $raw.MaxWindowSize
        if (-not $max -or $max.Width -le 0) { $max = $raw.LargestWindowSize }
        if ($max -and $max.Width -gt 0 -and $max.Height -gt 0) {
            $Width = [Math]::Min($Width, $max.Width)
            $Height = [Math]::Min($Height, $max.Height)
        }
        $bufW = [Math]::Max($Width, $raw.BufferSize.Width)
        $bufH = [Math]::Max($BufferHeight, $Height)
        $raw.BufferSize = New-Object Management.Automation.Host.Size($bufW, $bufH)
        $raw.WindowSize = New-Object Management.Automation.Host.Size($Width, $Height)
    }
    catch {}
}

$script:ApiEnc = "L0ZpbGVzL0NvbnRyb2xsZXJzL0NvbnRyb2xsZXJzQWxsLnBocA=="
$script:ApiEndpoint = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($script:ApiEnc))

$script:Lang = "en_US"
$script:Locales = [ordered]@{
    "cs_CZ" = "Czech"
    "de_DE" = "German"
    "en_US" = "English"
    "es_ES" = "Spanish"
    "fr_FR" = "French"
    "hi_IN" = "Hindi"
    "hu_HU" = "Hungarian"
    "it_IT" = "Italian"
    "ja_JP" = "Japanese"
    "nb_NO" = "Norwegian Bokmal"
    "nl_NL" = "Dutch"
    "pl_PL" = "Polish"
    "pt_BR" = "Portuguese"
    "ro_RO" = "Romanian"
    "ru_RU" = "Russian"
    "sv_SE" = "Swedish"
    "tr_TR" = "Turkish"
    "vi_VN" = "Vietnamese"
    "zh_CN" = "Chinese"
}

$script:Translations = @{
    "en_US" = @{
        "ui.select_language"        = "Select Language"
        "ui.use_arrows"             = "Use UP/DOWN arrows to navigate, ENTER to select."
        "ui.loading"                = "Loading, please wait..."
        "header.tagline1"           = "Powerful, secure and scalable infrastructure for modern projects."
        "header.tagline2"           = "Game, licensing, hosting, integrations and management in one place."
        "header.website"            = "Website"
        "header.discord"            = "Discord"
        "prompt.yes_no"             = "{0} (yes/no): "
        "prompt.press_enter"        = "Press Enter to continue..."
        "prompt.press_enter_done"   = "Press Enter when complete..."
        "prompt.email"              = "Email"
        "prompt.password"           = "Password"
        "prompt.first_name"         = "First Name"
        "prompt.last_name"          = "Last Name"
        "prompt.confirm_password"   = "Confirm Password"
        "prompt.license_id"         = "License ID"
        "prompt.license_id_default" = "License ID"
        "prompt.new_domain"         = "Enter New Domain Name"
        "prompt.buy_domain"         = "Enter Domain to Buy License For"
        "msg.answer_yes_no"         = "Please answer yes or no."
        "msg.base_url_missing"      = "Base URL not set. Configure BaseUrl/BaseUrlEnc or env vars."
        "msg.load_cookies_fail"     = "Failed to load cookies: {0}"
        "msg.save_cookies_fail"     = "Failed to save cookies: {0}"
        "msg.read_license_fail"     = "Failed to read license data: {0}"
        "msg.save_license_ok"       = "License info saved locally."
        "msg.save_license_fail"     = "Failed to save license data: {0}"
        "msg.current_license"       = "Current License Info:"
        "msg.license_id"            = "- License ID: {0}"
        "msg.domain"                = "- Domain: {0}"
        "msg.expiry"                = "- Expiry Date: {0}"
        "msg.db_host"               = "- DB Host: {0}"
        "msg.db_port"               = "- DB Port: {0}"
        "msg.db_user"               = "- DB Username: {0}"
        "msg.db_pass"               = "- DB Password: {0}"
        "msg.db_name"               = "- DB Name: {0}"
        "msg.cloudflare"            = "Cloudflare detected (CSRF page)."
        "prompt.cookie_header"      = "Please enter Browser Cookie Header (cf_clearance=...; __cf_bm=...)"
        "msg.csrf_failed"           = "Failed to get CSRF token. Error: {0}"
        "msg.login_success"         = "Login successful."
        "msg.login_failed"          = "Login failed."
        "msg.login_2fa"             = "Two-factor authentication required. Please complete login on the website."
        "msg.unexpected_response"   = "Unexpected response from server."
        "msg.register_success"      = "Registration successful."
        "msg.register_failed"       = "Registration failed."
        "msg.register_mismatch"     = "Passwords do not match."
        "msg.register_auto"         = "Registration successful! Logged in automatically."
        "msg.logged_out"            = "Logged out."
        "msg.list_fail"             = "Failed to retrieve license list. Session might have expired."
        "msg.invalid_license"       = "That is not a valid License ID."
        "msg.license_detail_fail"   = "Could not fetch license details."
        "msg.invalid_domain"        = "Invalid domain name."
        "msg.txt_required"          = "TXT Verification Required:"
        "msg.txt_add"               = "Add this TXT record to your domain DNS:"
        "msg.txt_type"              = "Type: TXT"
        "msg.txt_host"              = "Host: @"
        "msg.txt_value"             = "Value: ZONELY-{0}"
        "msg.txt_added"             = "Have you added the TXT record?"
        "msg.verifying"             = "Verifying..."
        "msg.txt_verified"          = "TXT Verified!"
        "msg.txt_failed"            = "TXT verification failed."
        "msg.retry_verify"          = "Retry verification?"
        "msg.domain_updated"        = "Domain updated successfully."
        "msg.domain_update_fail"    = "Failed to update domain."
        "msg.setup_starting"        = "Starting Auto Setup..."
        "msg.setup_finished"        = "Setup process finished."
        "msg.setup_start_fail"      = "Could not start auto setup."
        "msg.sql_ok"                = "SQL dump downloaded to: {0}"
        "msg.sql_empty"             = "SQL dump failed (empty file)."
        "msg.sql_error"             = "SQL dump error: {0}"
        "msg.authme_build_fail"     = "Could not build AuthMe config."
        "msg.authme_saved"          = "AuthMe config saved to: {0}"
        "msg.authme_info_fail"      = "Could not fetch license info for config."
        "msg.db_info"               = "Database Information:"
        "msg.db_host_line"          = "Host: {0}"
        "msg.db_port_line"          = "Port: {0}"
        "msg.db_user_line"          = "Username: {0}"
        "msg.db_pass_line"          = "Password: {0}"
        "msg.db_name_line"          = "DB Name: {0}"
        "msg.db_phpmyadmin"         = "phpMyAdmin: {0}"
        "msg.dns_required"          = "DNS Verification Required"
        "msg.dns_add"               = "Please add these records to your DNS panel:"
        "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Enabled)"
        "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Enabled)"
        "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
        "msg.dns_added"             = "Have you added the DNS records?"
        "msg.dns_failed"            = "Verification failed. Check your DNS."
        "msg.retry"                 = "Retry?"
        "msg.creating_license"      = "Creating license..."
        "msg.license_purchased"     = "License purchased successfully!"
        "msg.starting_initial"      = "Starting initial setup..."
        "msg.license_setup_started" = "License setup started. It will be ready in ~30 minutes."
        "msg.purchase_failed"       = "Purchase failed."
        "msg.discord_token_missing" = "rememberMe token not found. Please login first."
        "msg.discord_opening"       = "Opening Discord verification: {0}"
        "msg.browser_open_fail"     = "Could not open browser."
        "msg.discord_opened"        = "Discord verification opened. Press Enter when complete..."
        "msg.update_checking"       = "Checking for updates..."
        "msg.update_available"      = "Update available: {0} -> {1}. Downloading..."
        "msg.update_success"        = "Update complete. Restarting..."
        "msg.update_failed"         = "Update failed: {0}"
        "msg.fatal_error"           = "Fatal Error: {0}"
        "msg.no_licenses"           = "No licenses found."
        "msg.licenses_header"       = "-- Your Licenses --"
        "msg.license_line"          = "| Domain: {0} | Expiry: {1}"
        "msg.setup_wait"            = "Setup started. Waiting for progress..."
        "msg.setup_timeout"         = "Installation might be timing out."
        "msg.size_warning"          = "Window size could not be adjusted. If you are using Windows Terminal/VSCode, resize the window manually or run from classic CMD for best view."
        "label.setup"               = "Setup"
        "menu.welcome"              = "Welcome! Please login or register."
        "menu.login"                = "Login"
        "menu.register"             = "Register"
        "menu.exit"                 = "Exit"
        "menu.main"                 = "Main Menu"
        "menu.list"                 = "List Licenses"
        "menu.details"              = "View License Details"
        "menu.update_domain"        = "Update Domain"
        "menu.autosetup"            = "Start Auto Setup"
        "menu.sqldump"              = "Download SQL Dump"
        "menu.authme"               = "Generate AuthMe Config"
        "menu.dbinfo"               = "View DB Credentials"
        "menu.buy"                  = "Buy New License"
        "menu.discord"              = "Discord Role Verify"
        "menu.logout"               = "Logout"
    }
    "tr_TR" = @{
        "ui.select_language"        = "Dil Seçimi"
        "ui.use_arrows"             = "Yukarı/Aşağı oklarıyla gezinin, ENTER ile seçin."
        "ui.loading"                = "Yükleniyor, lütfen bekleyin..."
        "header.tagline1"           = "Modern projeler için güçlü, güvenli ve ölçeklenebilir altyapı."
        "header.tagline2"           = "Oyun, lisanslama, hosting, entegrasyon ve yönetim tek yerde."
        "header.website"            = "Web Sitesi"
        "header.discord"            = "Discord"
        "prompt.yes_no"             = "{0} (evet/hayır): "
        "prompt.press_enter"        = "Devam etmek için Enter..."
        "prompt.press_enter_done"   = "Bitince Enter..."
        "prompt.email"              = "E-posta"
        "prompt.password"           = "Şifre"
        "prompt.first_name"         = "İsim"
        "prompt.last_name"          = "Soyisim"
        "prompt.confirm_password"   = "Şifre (tekrar)"
        "prompt.license_id"         = "Lisans ID"
        "prompt.license_id_default" = "Lisans ID"
        "prompt.new_domain"         = "Yeni Alan Adı"
        "prompt.buy_domain"         = "Lisans alınacak alan adı"
        "msg.answer_yes_no"         = "Lütfen evet veya hayır olarak cevaplayın."
        "msg.base_url_missing"      = "Base URL ayarlı değil. BaseUrl/BaseUrlEnc veya env ile ayarlayın."
        "msg.load_cookies_fail"     = "Çerezler yüklenemedi: {0}"
        "msg.save_cookies_fail"     = "Çerezler kaydedilemedi: {0}"
        "msg.read_license_fail"     = "Lisans bilgisi okunamadı: {0}"
        "msg.save_license_ok"       = "Lisans bilgisi yerel olarak kaydedildi."
        "msg.save_license_fail"     = "Lisans bilgisi kaydedilemedi: {0}"
        "msg.current_license"       = "Güncel Lisans Bilgisi:"
        "msg.license_id"            = "- Lisans ID: {0}"
        "msg.domain"                = "- Alan adı: {0}"
        "msg.expiry"                = "- Bitiş Tarihi: {0}"
        "msg.db_host"               = "- DB Host: {0}"
        "msg.db_port"               = "- DB Port: {0}"
        "msg.db_user"               = "- DB Kullanıcı: {0}"
        "msg.db_pass"               = "- DB Şifre: {0}"
        "msg.db_name"               = "- DB Adı: {0}"
        "msg.cloudflare"            = "Cloudflare koruması algılandı (CSRF sayfası)."
        "prompt.cookie_header"      = "Tarayıcıdan Cookie Header girin (cf_clearance=...; __cf_bm=...)"
        "msg.csrf_failed"           = "CSRF token alınamadı. Hata: {0}"
        "msg.login_success"         = "Giriş başarılı."
        "msg.login_failed"          = "Giriş başarısız."
        "msg.login_2fa"             = "İki adımlı doğrulama gerekiyor. Lütfen web sitesinden tamamlayın."
        "msg.unexpected_response"   = "Sunucudan beklenmeyen cevap."
        "msg.register_success"      = "Kayıt başarılı."
        "msg.register_failed"       = "Kayıt başarısız."
        "msg.register_mismatch"     = "Şifreler eşleşmiyor."
        "msg.register_auto"         = "Kayıt başarılı! Otomatik giriş yapıldı."
        "msg.logged_out"            = "Çıkış yapıldı."
        "msg.list_fail"             = "Lisans listesi alınamadı. Oturum süresi dolmuş olabilir."
        "msg.invalid_license"       = "Geçerli bir Lisans ID değil."
        "msg.license_detail_fail"   = "Lisans detayı alınamadı."
        "msg.invalid_domain"        = "Geçersiz alan adı."
        "msg.txt_required"          = "TXT Doğrulama Gerekli:"
        "msg.txt_add"               = "DNS paneline şu TXT kaydını ekleyin:"
        "msg.txt_type"              = "Tür: TXT"
        "msg.txt_host"              = "Host: @"
        "msg.txt_value"             = "Değer: ZONELY-{0}"
        "msg.txt_added"             = "TXT kaydını eklediniz mi?"
        "msg.verifying"             = "Doğrulanıyor..."
        "msg.txt_verified"          = "TXT doğrulandı!"
        "msg.txt_failed"            = "TXT doğrulama başarısız."
        "msg.retry_verify"          = "Tekrar denensin mi?"
        "msg.domain_updated"        = "Alan adı güncellendi."
        "msg.domain_update_fail"    = "Alan adı güncellenemedi."
        "msg.setup_starting"        = "Kurulum başlatılıyor..."
        "msg.setup_finished"        = "Kurulum tamamlandı."
        "msg.setup_start_fail"      = "Kurulum başlatılamadı."
        "msg.sql_ok"                = "SQL dump indirildi: {0}"
        "msg.sql_empty"             = "SQL dump başarısız (boş dosya)."
        "msg.sql_error"             = "SQL dump hatası: {0}"
        "msg.authme_build_fail"     = "AuthMe config oluşturulamadı."
        "msg.authme_saved"          = "AuthMe config kaydedildi: {0}"
        "msg.authme_info_fail"      = "Config için lisans bilgisi alınamadı."
        "msg.db_info"               = "Veritabanı Bilgileri:"
        "msg.db_host_line"          = "Host: {0}"
        "msg.db_port_line"          = "Port: {0}"
        "msg.db_user_line"          = "Kullanıcı: {0}"
        "msg.db_pass_line"          = "Şifre: {0}"
        "msg.db_name_line"          = "DB Adı: {0}"
        "msg.db_phpmyadmin"         = "phpMyAdmin Giriş: {0}"
        "msg.dns_required"          = "DNS Doğrulama Gerekli"
        "msg.dns_add"               = "DNS paneline şu kayıtları ekleyin:"
        "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Bulut Aktif)"
        "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Bulut Aktif)"
        "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
        "msg.dns_added"             = "DNS kayıtlarını eklediniz mi?"
        "msg.dns_failed"            = "Doğrulama başarısız. DNS kayıtlarını kontrol edin."
        "msg.retry"                 = "Tekrar denensin mi?"
        "msg.creating_license"      = "Lisans oluşturuluyor..."
        "msg.license_purchased"     = "Lisans başarıyla alındı!"
        "msg.starting_initial"      = "İlk kurulum başlatılıyor..."
        "msg.license_setup_started" = "Lisans kurulumu başladı. Yaklaşık 30 dakika sonra hazır."
        "msg.purchase_failed"       = "Satın alma başarısız."
        "msg.discord_token_missing" = "rememberMe token bulunamadı. Önce giriş yapın."
        "msg.discord_opening"       = "Discord doğrulama açılıyor: {0}"
        "msg.browser_open_fail"     = "Tarayıcı açılamadı."
        "msg.discord_opened"        = "Discord doğrulama açıldı. Bitince Enter..."
        "msg.update_checking"       = "Güncellemeler kontrol ediliyor..."
        "msg.update_available"      = "Güncelleme mevcut: {0} -> {1}. İndiriliyor..."
        "msg.update_success"        = "Güncelleme tamamlandı. Yeniden başlatılıyor..."
        "msg.update_failed"         = "Güncelleme başarısız: {0}"
        "msg.fatal_error"           = "Kritik Hata: {0}"
        "msg.no_licenses"           = "Lisans bulunamadı."
        "msg.licenses_header"       = "-- Lisanslarınız --"
        "msg.license_line"          = "| Alan adı: {0} | Bitiş: {1}"
        "msg.setup_wait"            = "Kurulum başladı. İlerleme bekleniyor..."
        "msg.setup_timeout"         = "Kurulum zaman aşımına uğruyor olabilir."
        "msg.size_warning"          = "Pencere boyutu ayarlanamadi. Windows Terminal/VSCode kullaniyorsan elle buyut veya klasik CMD ile ac."
        "label.setup"               = "Kurulum"
        "menu.welcome"              = "Hoş geldiniz! Lütfen giriş yapın veya kayıt olun."
        "menu.login"                = "Giriş"
        "menu.register"             = "Kayıt"
        "menu.exit"                 = "Çıkış"
        "menu.main"                 = "Ana Menü"
        "menu.list"                 = "Lisansları Listele"
        "menu.details"              = "Lisans Detayı"
        "menu.update_domain"        = "Alan Adı Güncelle"
        "menu.autosetup"            = "Kurulum Başlat"
        "menu.sqldump"              = "SQL Dump İndir"
        "menu.authme"               = "AuthMe Config Oluştur"
        "menu.dbinfo"               = "Veritabanı Bilgileri"
        "menu.buy"                  = "Yeni Lisans Al"
        "menu.discord"              = "Discord Rol Doğrula"
        "menu.logout"               = "Çıkış Yap"
    }
}

$script:Translations["cs_CZ"] = @{
    "ui.select_language"        = "Vyber jazyka"
    "ui.use_arrows"             = "Pouzij sipky NAHORU/DOLU, ENTER pro vyber."
    "ui.loading"                = "Nahravam, prosim cekej..."
    "header.tagline1"           = "Vykonna, bezpecna a skalovatelna infrastruktura pro moderni projekty."
    "header.tagline2"           = "Hry, licencovani, hosting, integrace a sprava na jednom miste."
    "header.website"            = "Web"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (ano/ne): "
    "prompt.press_enter"        = "Pro pokracovani stiskni Enter..."
    "prompt.press_enter_done"   = "Po dokonceni stiskni Enter..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Heslo"
    "prompt.first_name"         = "Jmeno"
    "prompt.last_name"          = "Prijmeni"
    "prompt.confirm_password"   = "Potvrd heslo"
    "prompt.license_id"         = "ID licence"
    "prompt.license_id_default" = "ID licence"
    "prompt.new_domain"         = "Zadej novou domenu"
    "prompt.buy_domain"         = "Zadej domenu pro koupi licence"
    "msg.answer_yes_no"         = "Odpovez prosim ano nebo ne."
    "msg.base_url_missing"      = "Base URL nenastaveno. Nastav BaseUrl/BaseUrlEnc nebo env."
    "msg.load_cookies_fail"     = "Nepodarilo se nacist cookies: {0}"
    "msg.save_cookies_fail"     = "Nepodarilo se ulozit cookies: {0}"
    "msg.read_license_fail"     = "Nepodarilo se precist data licence: {0}"
    "msg.save_license_ok"       = "Informace o licenci ulozeny."
    "msg.save_license_fail"     = "Nepodarilo se ulozit data licence: {0}"
    "msg.current_license"       = "Aktualni informace o licenci:"
    "msg.license_id"            = "- ID licence: {0}"
    "msg.domain"                = "- Domena: {0}"
    "msg.expiry"                = "- Datum vyprseni: {0}"
    "msg.db_host"               = "- DB Host: {0}"
    "msg.db_port"               = "- DB Port: {0}"
    "msg.db_user"               = "- DB Uzivatel: {0}"
    "msg.db_pass"               = "- DB Heslo: {0}"
    "msg.db_name"               = "- DB Nazev: {0}"
    "msg.cloudflare"            = "Cloudflare detekovan (CSRF stranka)."
    "prompt.cookie_header"      = "Zadej Cookie header z prohlizece (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Nepodarilo se ziskat CSRF token. Chyba: {0}"
    "msg.login_success"         = "Prihlaseni uspesne."
    "msg.login_failed"          = "Prihlaseni selhalo."
    "msg.login_2fa"             = "Vyzadovana 2FA. Dokoncete prihlaseni na webu."
    "msg.unexpected_response"   = "Neocekavana odpoved ze serveru."
    "msg.register_success"      = "Registrace uspesna."
    "msg.register_failed"       = "Registrace selhala."
    "msg.register_mismatch"     = "Hesla se neshoduji."
    "msg.register_auto"         = "Registrace uspesna! Automaticky prihlaseno."
    "msg.logged_out"            = "Odhlaseno."
    "msg.list_fail"             = "Nepodarilo se nacist seznam licenci. Relace mohla vyprset."
    "msg.invalid_license"       = "To neni platne ID licence."
    "msg.license_detail_fail"   = "Nepodarilo se nacist detaily licence."
    "msg.invalid_domain"        = "Neplatna domena."
    "msg.txt_required"          = "Vyzadovano TXT overeni:"
    "msg.txt_add"               = "Pridej tento TXT zaznam do DNS:"
    "msg.txt_type"              = "Typ: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Hodnota: ZONELY-{0}"
    "msg.txt_added"             = "Pridal jsi TXT zaznam?"
    "msg.verifying"             = "Overuji..."
    "msg.txt_verified"          = "TXT overen!"
    "msg.txt_failed"            = "TXT overeni selhalo."
    "msg.retry_verify"          = "Zkusit overeni znovu?"
    "msg.domain_updated"        = "Domena aktualizovana."
    "msg.domain_update_fail"    = "Aktualizace domeny selhala."
    "msg.setup_starting"        = "Spoustim Auto Setup..."
    "msg.setup_finished"        = "Setup dokoncen."
    "msg.setup_start_fail"      = "Auto Setup nelze spustit."
    "msg.sql_ok"                = "SQL dump stazen do: {0}"
    "msg.sql_empty"             = "SQL dump selhal (prazdny soubor)."
    "msg.sql_error"             = "Chyba SQL dumpu: {0}"
    "msg.authme_build_fail"     = "Nepodarilo se vytvorit AuthMe config."
    "msg.authme_saved"          = "AuthMe config ulozen do: {0}"
    "msg.authme_info_fail"      = "Nelze ziskat info o licenci pro config."
    "msg.db_info"               = "Informace o databazi:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Port: {0}"
    "msg.db_user_line"          = "Uzivatel: {0}"
    "msg.db_pass_line"          = "Heslo: {0}"
    "msg.db_name_line"          = "DB Nazev: {0}"
    "msg.dns_required"          = "Vyzadovano DNS overeni"
    "msg.dns_add"               = "Pridejte tyto DNS zaznamy:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Zapnut)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Zapnut)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Pridals DNS zaznamy?"
    "msg.dns_failed"            = "Overeni selhalo. Zkontroluj DNS."
    "msg.retry"                 = "Zkusit znovu?"
    "msg.creating_license"      = "Vytvarim licenci..."
    "msg.license_purchased"     = "Licence uspesne zakoupena!"
    "msg.starting_initial"      = "Spoustim pocatecni setup..."
    "msg.license_setup_started" = "Setup licence zahajen. Bude hotovo cca za 30 minut."
    "msg.purchase_failed"       = "Nakup selhal."
    "msg.discord_token_missing" = "rememberMe token nenalezen. Nejprve se prihlas."
    "msg.discord_opening"       = "Oteviram Discord overeni: {0}"
    "msg.browser_open_fail"     = "Nelze otevrit prohlizec."
    "msg.discord_opened"        = "Discord overeni otevreno. Po dokonceni Enter..."
    "msg.fatal_error"           = "Kriticka chyba: {0}"
    "msg.no_licenses"           = "Nenalezeny zadne licence."
    "msg.licenses_header"       = "-- Tvoje licence --"
    "msg.license_line"          = "| Domena: {0} | Vyprseni: {1}"
    "msg.setup_wait"            = "Setup zahajen. Cekam na postup..."
    "msg.setup_timeout"         = "Instalace muze trvat prilis dlouho."
    "label.setup"               = "Setup"
    "menu.welcome"              = "Vitej! Prosim prihlas se nebo registruj."
    "menu.login"                = "Prihlasit"
    "menu.register"             = "Registrovat"
    "menu.exit"                 = "Konec"
    "menu.main"                 = "Hlavni menu"
    "menu.list"                 = "Seznam licenci"
    "menu.details"              = "Detaily licence"
    "menu.update_domain"        = "Aktualizovat domenu"
    "menu.autosetup"            = "Spustit Auto Setup"
    "menu.sqldump"              = "Stahnout SQL Dump"
    "menu.authme"               = "Vytvorit AuthMe Config"
    "menu.dbinfo"               = "DB Prihlasovaci udaje"
    "menu.buy"                  = "Koupit novou licenci"
    "menu.discord"              = "Overit Discord roli"
    "menu.logout"               = "Odhlasit"
}

$script:Translations["de_DE"] = @{
    "ui.select_language"        = "Sprache auswahlen"
    "ui.use_arrows"             = "Mit PFEIL AUF/AB navigieren, ENTER auswahlen."
    "ui.loading"                = "Lade, bitte warten..."
    "header.tagline1"           = "Leistungsstarke, sichere und skalierbare Infrastruktur fur moderne Projekte."
    "header.tagline2"           = "Game, Lizenzierung, Hosting, Integrationen und Verwaltung an einem Ort."
    "header.website"            = "Webseite"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (ja/nein): "
    "prompt.press_enter"        = "Zum Fortfahren Enter..."
    "prompt.press_enter_done"   = "Wenn fertig, Enter..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Passwort"
    "prompt.first_name"         = "Vorname"
    "prompt.last_name"          = "Nachname"
    "prompt.confirm_password"   = "Passwort bestatigen"
    "prompt.license_id"         = "Lizenz ID"
    "prompt.license_id_default" = "Lizenz ID"
    "prompt.new_domain"         = "Neue Domain eingeben"
    "prompt.buy_domain"         = "Domain fur Lizenzkauf eingeben"
    "msg.answer_yes_no"         = "Bitte ja oder nein antworten."
    "msg.base_url_missing"      = "Base URL nicht gesetzt. BaseUrl/BaseUrlEnc oder env konfigurieren."
    "msg.load_cookies_fail"     = "Cookies konnten nicht geladen werden: {0}"
    "msg.save_cookies_fail"     = "Cookies konnten nicht gespeichert werden: {0}"
    "msg.read_license_fail"     = "Lizenzdaten konnten nicht gelesen werden: {0}"
    "msg.save_license_ok"       = "Lizenzinfo lokal gespeichert."
    "msg.save_license_fail"     = "Lizenzdaten konnten nicht gespeichert werden: {0}"
    "msg.current_license"       = "Aktuelle Lizenzinfo:"
    "msg.license_id"            = "- Lizenz ID: {0}"
    "msg.domain"                = "- Domain: {0}"
    "msg.expiry"                = "- Ablaufdatum: {0}"
    "msg.db_host"               = "- DB Host: {0}"
    "msg.db_port"               = "- DB Port: {0}"
    "msg.db_user"               = "- DB Benutzer: {0}"
    "msg.db_pass"               = "- DB Passwort: {0}"
    "msg.db_name"               = "- DB Name: {0}"
    "msg.cloudflare"            = "Cloudflare erkannt (CSRF Seite)."
    "prompt.cookie_header"      = "Browser Cookie Header eingeben (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "CSRF Token konnte nicht geholt werden. Fehler: {0}"
    "msg.login_success"         = "Login erfolgreich."
    "msg.login_failed"          = "Login fehlgeschlagen."
    "msg.login_2fa"             = "Zwei-Faktor-Authentifizierung erforderlich. Bitte auf der Webseite abschliessen."
    "msg.unexpected_response"   = "Unerwartete Antwort vom Server."
    "msg.register_success"      = "Registrierung erfolgreich."
    "msg.register_failed"       = "Registrierung fehlgeschlagen."
    "msg.register_mismatch"     = "Passworter stimmen nicht uberein."
    "msg.register_auto"         = "Registrierung erfolgreich! Automatisch eingeloggt."
    "msg.logged_out"            = "Abgemeldet."
    "msg.list_fail"             = "Lizenzliste konnte nicht abgerufen werden. Sitzung evtl. abgelaufen."
    "msg.invalid_license"       = "Das ist keine gultige Lizenz ID."
    "msg.license_detail_fail"   = "Lizenzdetails konnten nicht geladen werden."
    "msg.invalid_domain"        = "Ungultige Domain."
    "msg.txt_required"          = "TXT Verifizierung erforderlich:"
    "msg.txt_add"               = "Fuge diesen TXT Eintrag in DNS hinzu:"
    "msg.txt_type"              = "Typ: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Wert: ZONELY-{0}"
    "msg.txt_added"             = "Hast du den TXT Eintrag hinzugefugt?"
    "msg.verifying"             = "Prufe..."
    "msg.txt_verified"          = "TXT verifiziert!"
    "msg.txt_failed"            = "TXT Verifizierung fehlgeschlagen."
    "msg.retry_verify"          = "Verifizierung wiederholen?"
    "msg.domain_updated"        = "Domain erfolgreich aktualisiert."
    "msg.domain_update_fail"    = "Domain konnte nicht aktualisiert werden."
    "msg.setup_starting"        = "Auto Setup startet..."
    "msg.setup_finished"        = "Setup abgeschlossen."
    "msg.setup_start_fail"      = "Auto Setup konnte nicht gestartet werden."
    "msg.sql_ok"                = "SQL Dump heruntergeladen nach: {0}"
    "msg.sql_empty"             = "SQL Dump fehlgeschlagen (leere Datei)."
    "msg.sql_error"             = "SQL Dump Fehler: {0}"
    "msg.authme_build_fail"     = "AuthMe Config konnte nicht erstellt werden."
    "msg.authme_saved"          = "AuthMe Config gespeichert: {0}"
    "msg.authme_info_fail"      = "Lizenzinfo fur Config konnte nicht geladen werden."
    "msg.db_info"               = "Datenbank Informationen:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Port: {0}"
    "msg.db_user_line"          = "Benutzername: {0}"
    "msg.db_pass_line"          = "Passwort: {0}"
    "msg.db_name_line"          = "DB Name: {0}"
    "msg.dns_required"          = "DNS Verifizierung erforderlich"
    "msg.dns_add"               = "Bitte folgende DNS Eintrage hinzufugen:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Aktiv)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Aktiv)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Hast du die DNS Eintrage hinzugefugt?"
    "msg.dns_failed"            = "Verifizierung fehlgeschlagen. DNS prufen."
    "msg.retry"                 = "Erneut versuchen?"
    "msg.creating_license"      = "Lizenz wird erstellt..."
    "msg.license_purchased"     = "Lizenz erfolgreich gekauft!"
    "msg.starting_initial"      = "Starte Initial-Setup..."
    "msg.license_setup_started" = "Lizenz-Setup gestartet. In ca. 30 Minuten bereit."
    "msg.purchase_failed"       = "Kauf fehlgeschlagen."
    "msg.discord_token_missing" = "rememberMe Token nicht gefunden. Bitte zuerst einloggen."
    "msg.discord_opening"       = "Discord Verifizierung offnen: {0}"
    "msg.browser_open_fail"     = "Browser konnte nicht geoffnet werden."
    "msg.discord_opened"        = "Discord Verifizierung geoffnet. Wenn fertig, Enter..."
    "msg.fatal_error"           = "Fataler Fehler: {0}"
    "msg.no_licenses"           = "Keine Lizenzen gefunden."
    "msg.licenses_header"       = "-- Ihre Lizenzen --"
    "msg.license_line"          = "| Domain: {0} | Ablauf: {1}"
    "msg.setup_wait"            = "Setup gestartet. Warte auf Fortschritt..."
    "msg.setup_timeout"         = "Installation braucht moglicherweise zu lange."
    "label.setup"               = "Setup"
    "menu.welcome"              = "Willkommen! Bitte einloggen oder registrieren."
    "menu.login"                = "Anmelden"
    "menu.register"             = "Registrieren"
    "menu.exit"                 = "Beenden"
    "menu.main"                 = "Hauptmenu"
    "menu.list"                 = "Lizenzen auflisten"
    "menu.details"              = "Lizenzdetails anzeigen"
    "menu.update_domain"        = "Domain aktualisieren"
    "menu.autosetup"            = "Auto Setup starten"
    "menu.sqldump"              = "SQL Dump herunterladen"
    "menu.authme"               = "AuthMe Config erzeugen"
    "menu.dbinfo"               = "DB Zugangsdaten"
    "menu.buy"                  = "Neue Lizenz kaufen"
    "menu.discord"              = "Discord Rolle verifizieren"
    "menu.logout"               = "Abmelden"
}

$script:Translations["es_ES"] = @{
    "ui.select_language"        = "Seleccionar idioma"
    "ui.use_arrows"             = "Usa FLECHAS ARRIBA/ABAJO, ENTER para seleccionar."
    "ui.loading"                = "Cargando, por favor espera..."
    "header.tagline1"           = "Infraestructura potente, segura y escalable para proyectos modernos."
    "header.tagline2"           = "Juegos, licencias, hosting, integraciones y gestion en un solo lugar."
    "header.website"            = "Sitio web"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (si/no): "
    "prompt.press_enter"        = "Presiona Enter para continuar..."
    "prompt.press_enter_done"   = "Presiona Enter cuando termine..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Contrasena"
    "prompt.first_name"         = "Nombre"
    "prompt.last_name"          = "Apellido"
    "prompt.confirm_password"   = "Confirmar contrasena"
    "prompt.license_id"         = "ID de licencia"
    "prompt.license_id_default" = "ID de licencia"
    "prompt.new_domain"         = "Ingresar nuevo dominio"
    "prompt.buy_domain"         = "Ingresar dominio para comprar licencia"
    "msg.answer_yes_no"         = "Por favor responde si o no."
    "msg.base_url_missing"      = "Base URL no configurada. Configura BaseUrl/BaseUrlEnc o env."
    "msg.load_cookies_fail"     = "No se pudieron cargar cookies: {0}"
    "msg.save_cookies_fail"     = "No se pudieron guardar cookies: {0}"
    "msg.read_license_fail"     = "No se pudieron leer los datos de la licencia: {0}"
    "msg.save_license_ok"       = "Informacion de licencia guardada localmente."
    "msg.save_license_fail"     = "No se pudieron guardar los datos de la licencia: {0}"
    "msg.current_license"       = "Informacion actual de licencia:"
    "msg.license_id"            = "- ID de licencia: {0}"
    "msg.domain"                = "- Dominio: {0}"
    "msg.expiry"                = "- Fecha de vencimiento: {0}"
    "msg.db_host"               = "- Host DB: {0}"
    "msg.db_port"               = "- Puerto DB: {0}"
    "msg.db_user"               = "- Usuario DB: {0}"
    "msg.db_pass"               = "- Contrasena DB: {0}"
    "msg.db_name"               = "- Nombre DB: {0}"
    "msg.cloudflare"            = "Cloudflare detectado (pagina CSRF)."
    "prompt.cookie_header"      = "Ingresa Cookie Header del navegador (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "No se pudo obtener CSRF token. Error: {0}"
    "msg.login_success"         = "Inicio de sesion exitoso."
    "msg.login_failed"          = "Inicio de sesion fallido."
    "msg.login_2fa"             = "Se requiere 2FA. Completa el login en el sitio web."
    "msg.unexpected_response"   = "Respuesta inesperada del servidor."
    "msg.register_success"      = "Registro exitoso."
    "msg.register_failed"       = "Registro fallido."
    "msg.register_mismatch"     = "Las contrasenas no coinciden."
    "msg.register_auto"         = "Registro exitoso! Iniciaste sesion automaticamente."
    "msg.logged_out"            = "Sesion cerrada."
    "msg.list_fail"             = "No se pudo obtener la lista de licencias. La sesion pudo expirar."
    "msg.invalid_license"       = "No es un ID de licencia valido."
    "msg.license_detail_fail"   = "No se pudieron obtener los detalles de la licencia."
    "msg.invalid_domain"        = "Dominio invalido."
    "msg.txt_required"          = "Verificacion TXT requerida:"
    "msg.txt_add"               = "Agrega este registro TXT a tu DNS:"
    "msg.txt_type"              = "Tipo: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Valor: ZONELY-{0}"
    "msg.txt_added"             = "Agregaste el registro TXT?"
    "msg.verifying"             = "Verificando..."
    "msg.txt_verified"          = "TXT verificado!"
    "msg.txt_failed"            = "Verificacion TXT fallida."
    "msg.retry_verify"          = "Reintentar verificacion?"
    "msg.domain_updated"        = "Dominio actualizado correctamente."
    "msg.domain_update_fail"    = "No se pudo actualizar el dominio."
    "msg.setup_starting"        = "Iniciando Auto Setup..."
    "msg.setup_finished"        = "Proceso de instalacion finalizado."
    "msg.setup_start_fail"      = "No se pudo iniciar auto setup."
    "msg.sql_ok"                = "SQL dump descargado a: {0}"
    "msg.sql_empty"             = "SQL dump fallido (archivo vacio)."
    "msg.sql_error"             = "Error de SQL dump: {0}"
    "msg.authme_build_fail"     = "No se pudo crear AuthMe config."
    "msg.authme_saved"          = "AuthMe config guardado en: {0}"
    "msg.authme_info_fail"      = "No se pudo obtener info de licencia para config."
    "msg.db_info"               = "Informacion de base de datos:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Puerto: {0}"
    "msg.db_user_line"          = "Usuario: {0}"
    "msg.db_pass_line"          = "Contrasena: {0}"
    "msg.db_name_line"          = "Nombre DB: {0}"
    "msg.dns_required"          = "Verificacion DNS requerida"
    "msg.dns_add"               = "Agrega estos registros en tu panel DNS:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy activo)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy activo)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Agregaste los registros DNS?"
    "msg.dns_failed"            = "Verificacion fallida. Revisa tu DNS."
    "msg.retry"                 = "Reintentar?"
    "msg.creating_license"      = "Creando licencia..."
    "msg.license_purchased"     = "Licencia comprada correctamente!"
    "msg.starting_initial"      = "Iniciando configuracion inicial..."
    "msg.license_setup_started" = "Setup de licencia iniciado. Estara listo en ~30 minutos."
    "msg.purchase_failed"       = "Compra fallida."
    "msg.discord_token_missing" = "rememberMe token no encontrado. Inicia sesion primero."
    "msg.discord_opening"       = "Abriendo verificacion de Discord: {0}"
    "msg.browser_open_fail"     = "No se pudo abrir el navegador."
    "msg.discord_opened"        = "Verificacion de Discord abierta. Presiona Enter al terminar..."
    "msg.fatal_error"           = "Error fatal: {0}"
    "msg.no_licenses"           = "No se encontraron licencias."
    "msg.licenses_header"       = "-- Tus licencias --"
    "msg.license_line"          = "| Dominio: {0} | Vencimiento: {1}"
    "msg.setup_wait"            = "Setup iniciado. Esperando progreso..."
    "msg.setup_timeout"         = "La instalacion puede estar tardando demasiado."
    "label.setup"               = "Setup"
    "menu.welcome"              = "Bienvenido! Inicia sesion o registrate."
    "menu.login"                = "Iniciar sesion"
    "menu.register"             = "Registrarse"
    "menu.exit"                 = "Salir"
    "menu.main"                 = "Menu principal"
    "menu.list"                 = "Listar licencias"
    "menu.details"              = "Ver detalles de licencia"
    "menu.update_domain"        = "Actualizar dominio"
    "menu.autosetup"            = "Iniciar Auto Setup"
    "menu.sqldump"              = "Descargar SQL Dump"
    "menu.authme"               = "Generar AuthMe Config"
    "menu.dbinfo"               = "Ver credenciales DB"
    "menu.buy"                  = "Comprar nueva licencia"
    "menu.discord"              = "Verificar rol Discord"
    "menu.logout"               = "Cerrar sesion"
}

$script:Translations["fr_FR"] = @{
    "ui.select_language"        = "Sélectionner la langue"
    "ui.use_arrows"             = "Utilisez les flèches HAUT/BAS pour naviguer, ENTRÉE pour sélectionner."
    "ui.loading"                = "Chargement, veuillez patienter..."
    "header.tagline1"           = "Infrastructure puissante, sécurisée et évolutive pour les projets modernes."
    "header.tagline2"           = "Jeux, licences, hébergement, intégrations et gestion en un seul endroit."
    "header.website"            = "Site Web"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (oui/non) : "
    "prompt.press_enter"        = "Appuyez sur Entrée pour continuer..."
    "prompt.press_enter_done"   = "Appuyez sur Entrée une fois terminé..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Mot de passe"
    "prompt.first_name"         = "Prénom"
    "prompt.last_name"          = "Nom"
    "prompt.confirm_password"   = "Confirmer le mot de passe"
    "prompt.license_id"         = "ID de licence"
    "prompt.license_id_default" = "ID de licence"
    "prompt.new_domain"         = "Entrer le nouveau nom de domaine"
    "prompt.buy_domain"         = "Entrer le domaine pour l'achat de licence"
    "msg.answer_yes_no"         = "Veuillez répondre par oui ou non."
    "msg.base_url_missing"      = "URL de base non définie. Configurez BaseUrl/BaseUrlEnc ou les variables d'env."
    "msg.load_cookies_fail"     = "Échec du chargement des cookies : {0}"
    "msg.save_cookies_fail"     = "Échec de l'enregistrement des cookies : {0}"
    "msg.read_license_fail"     = "Échec de la lecture des données de licence : {0}"
    "msg.save_license_ok"       = "Infos de licence enregistrées localement."
    "msg.save_license_fail"     = "Échec de l'enregistrement des données de licence : {0}"
    "msg.current_license"       = "Infos de licence actuelles :"
    "msg.license_id"            = "- ID de licence : {0}"
    "msg.domain"                = "- Domaine : {0}"
    "msg.expiry"                = "- Date d'expiration : {0}"
    "msg.db_host"               = "- Hôte DB : {0}"
    "msg.db_port"               = "- Port DB : {0}"
    "msg.db_user"               = "- Utilisateur DB : {0}"
    "msg.db_pass"               = "- Mot de passe DB : {0}"
    "msg.db_name"               = "- Nom DB : {0}"
    "msg.cloudflare"            = "Cloudflare détecté (page CSRF)."
    "prompt.cookie_header"      = "Veuillez entrer l'en-tête Cookie du navigateur (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Échec de l'obtention du jeton CSRF. Erreur : {0}"
    "msg.login_success"         = "Connexion réussie."
    "msg.login_failed"          = "Échec de la connexion."
    "msg.login_2fa"             = "Authentification à deux facteurs requise. Veuillez terminer la connexion sur le site Web."
    "msg.unexpected_response"   = "Réponse inattendue du serveur."
    "msg.register_success"      = "Inscription réussie."
    "msg.register_failed"       = "Échec de l'inscription."
    "msg.register_mismatch"     = "Les mots de passe ne correspondent pas."
    "msg.register_auto"         = "Inscription réussie ! Connecté automatiquement."
    "msg.logged_out"            = "Déconnecté."
    "msg.list_fail"             = "Échec de la récupération de la liste des licences. La session a peut-être expiré."
    "msg.invalid_license"       = "Ce n'est pas un ID de licence valide."
    "msg.license_detail_fail"   = "Impossible de récupérer les détails de la licence."
    "msg.invalid_domain"        = "Nom de domaine invalide."
    "msg.txt_required"          = "Vérification TXT requise :"
    "msg.txt_add"               = "Ajoutez cet enregistrement TXT à votre DNS de domaine :"
    "msg.txt_type"              = "Type : TXT"
    "msg.txt_host"              = "Hôte : @"
    "msg.txt_value"             = "Valeur : ZONELY-{0}"
    "msg.txt_added"             = "Avez-vous ajouté l'enregistrement TXT ?"
    "msg.verifying"             = "Vérification..."
    "msg.txt_verified"          = "TXT Vérifié !"
    "msg.txt_failed"            = "Échec de la vérification TXT."
    "msg.retry_verify"          = "Réessayer la vérification ?"
    "msg.domain_updated"        = "Domaine mis à jour avec succès."
    "msg.domain_update_fail"    = "Échec de la mise à jour du domaine."
    "msg.setup_starting"        = "Démarrage de l'Auto Setup..."
    "msg.setup_finished"        = "Processus d'installation terminé."
    "msg.setup_start_fail"      = "Impossible de démarrer l'auto setup."
    "msg.sql_ok"                = "Dump SQL téléchargé vers : {0}"
    "msg.sql_empty"             = "Échec du dump SQL (fichier vide)."
    "msg.sql_error"             = "Erreur du dump SQL : {0}"
    "msg.authme_build_fail"     = "Impossible de construire la config AuthMe."
    "msg.authme_saved"          = "Config AuthMe enregistrée vers : {0}"
    "msg.authme_info_fail"      = "Impossible de récupérer les infos de licence pour la config."
    "msg.db_info"               = "Informations Base de Données :"
    "msg.db_host_line"          = "Hôte : {0}"
    "msg.db_port_line"          = "Port : {0}"
    "msg.db_user_line"          = "Utilisateur : {0}"
    "msg.db_pass_line"          = "Mot de passe : {0}"
    "msg.db_name_line"          = "Nom DB : {0}"
    "msg.dns_required"          = "Vérification DNS requise"
    "msg.dns_add"               = "Veuillez ajouter ces enregistrements à votre panneau DNS :"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Activé)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Activé)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Avez-vous ajouté les enregistrements DNS ?"
    "msg.dns_failed"            = "Vérification échouée. Vérifiez votre DNS."
    "msg.retry"                 = "Réessayer ?"
    "msg.creating_license"      = "Création de la licence..."
    "msg.license_purchased"     = "Licence achetée avec succès !"
    "msg.starting_initial"      = "Démarrage de la configuration initiale..."
    "msg.license_setup_started" = "Configuration de licence démarrée. Prêt dans ~30 minutes."
    "msg.purchase_failed"       = "Achat échoué."
    "msg.discord_token_missing" = "Jeton rememberMe introuvable. Veuillez vous connecter d'abord."
    "msg.discord_opening"       = "Ouverture vérification Discord : {0}"
    "msg.browser_open_fail"     = "Impossible d'ouvrir le navigateur."
    "msg.discord_opened"        = "Vérification Discord ouverte. Appuyez sur Entrée une fois terminé..."
    "msg.fatal_error"           = "Erreur Fatale : {0}"
    "msg.no_licenses"           = "Aucune licence trouvée."
    "msg.licenses_header"       = "-- Vos Licences --"
    "msg.license_line"          = "| Domaine : {0} | Expiration : {1}"
    "msg.setup_wait"            = "Installation démarrée. En attente de progression..."
    "msg.setup_timeout"         = "L'installation semble prendre trop de temps."
    "label.setup"               = "Installation"
    "menu.welcome"              = "Bienvenue ! Veuillez vous connecter ou vous inscrire."
    "menu.login"                = "Connexion"
    "menu.register"             = "Inscription"
    "menu.exit"                 = "Quitter"
    "menu.main"                 = "Menu Principal"
    "menu.list"                 = "Lister les Licences"
    "menu.details"              = "Voir Détails Licence"
    "menu.update_domain"        = "Mettre à jour Domaine"
    "menu.autosetup"            = "Démarrer Auto Setup"
    "menu.sqldump"              = "Télécharger Dump SQL"
    "menu.authme"               = "Générer Config AuthMe"
    "menu.dbinfo"               = "Voir Identifiants DB"
    "menu.buy"                  = "Acheter Nouvelle Licence"
    "menu.discord"              = "Vérifier Rôle Discord"
    "menu.logout"               = "Déconnexion"
}

$script:Translations["hi_IN"] = @{
    "ui.select_language"        = "भाषा चुनें"
    "ui.use_arrows"             = "नेविगेट करने के लिए ऊपर/नीचे तीरों का उपयोग करें, चयन करने के लिए ENTER दबाएं।"
    "ui.loading"                = "लोड हो रहा है, कृपया प्रतीक्षा करें..."
    "header.tagline1"           = "आधुनिक परियोजनाओं के लिए शक्तिशाली, सुरक्षित और स्केलेबल बुनियादी ढांचा।"
    "header.tagline2"           = "गेम, लाइसेंसिंग, होस्टिंग, एकीकरण और प्रबंधन सब एक जगह।"
    "header.website"            = "वेबसाइट"
    "header.discord"            = "डिस्कॉर्ड"
    "prompt.yes_no"             = "{0} (हां/नहीं): "
    "prompt.press_enter"        = "जारी रखने के लिए Enter दबाएं..."
    "prompt.press_enter_done"   = "पूरा होने पर Enter दबाएं..."
    "prompt.email"              = "ईमेल"
    "prompt.password"           = "पासवर्ड"
    "prompt.first_name"         = "पहला नाम"
    "prompt.last_name"          = "अंतिम नाम"
    "prompt.confirm_password"   = "पासवर्ड की पुष्टि करें"
    "prompt.license_id"         = "लाइसेंस ID"
    "prompt.license_id_default" = "लाइसेंस ID"
    "prompt.new_domain"         = "नया डोमेन नाम दर्ज करें"
    "prompt.buy_domain"         = "लाइसेंस खरीदने के लिए डोमेन दर्ज करें"
    "msg.answer_yes_no"         = "कृपया हां या नहीं में उत्तर दें।"
    "msg.base_url_missing"      = "बेस URL सेट नहीं है। BaseUrl/BaseUrlEnc या env को कॉन्फ़िगर करें।"
    "msg.load_cookies_fail"     = "कुकीज़ लोड करने में विफल: {0}"
    "msg.save_cookies_fail"     = "कुकीज़ सहेजने में विफल: {0}"
    "msg.read_license_fail"     = "लाइसेंस डेटा पढ़ने में विफल: {0}"
    "msg.save_license_ok"       = "लाइसेंस जानकारी स्थानीय रूप से सहेजी गई।"
    "msg.save_license_fail"     = "लाइसेंस डेटा सहेजने में विफल: {0}"
    "msg.current_license"       = "वर्तमान लाइसेंस जानकारी:"
    "msg.license_id"            = "- लाइसेंस ID: {0}"
    "msg.domain"                = "- डोमेन: {0}"
    "msg.expiry"                = "- समाप्ति तिथि: {0}"
    "msg.db_host"               = "- DB होस्ट: {0}"
    "msg.db_port"               = "- DB पोर्ट: {0}"
    "msg.db_user"               = "- DB उपयोगकर्ता: {0}"
    "msg.db_pass"               = "- DB पासवर्ड: {0}"
    "msg.db_name"               = "- DB नाम: {0}"
    "msg.cloudflare"            = "Cloudflare पता चला (CSRF पृष्ठ)।"
    "prompt.cookie_header"      = "कृपया ब्राउज़र कुकी हेडर दर्ज करें (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "CSRF टोकन प्राप्त करने में विफल। त्रुटि: {0}"
    "msg.login_success"         = "लॉगिन सफल।"
    "msg.login_failed"          = "लॉगिन विफल।"
    "msg.login_2fa"             = "दो-कारक प्रमाणीकरण आवश्यक है। कृपया वेबसाइट पर लॉगिन पूरा करें।"
    "msg.unexpected_response"   = "सर्वर से अप्रत्याशित प्रतिक्रिया।"
    "msg.register_success"      = "पंजीकरण सफल।"
    "msg.register_failed"       = "पंजीकरण विफल।"
    "msg.register_mismatch"     = "पासवर्ड मेल नहीं खाते।"
    "msg.register_auto"         = "पंजीकरण सफल! स्वचालित रूप से लॉग इन किया गया।"
    "msg.logged_out"            = "लॉग आउट किया गया।"
    "msg.list_fail"             = "लाइसेंस सूची प्राप्त करने में विफल। सत्र समाप्त हो सकता है।"
    "msg.invalid_license"       = "यह एक मान्य लाइसेंस ID नहीं है।"
    "msg.license_detail_fail"   = "लाइसेंस विवरण प्राप्त नहीं कर सका।"
    "msg.invalid_domain"        = "अमान्य डोमेन नाम।"
    "msg.txt_required"          = "TXT सत्यापन आवश्यक:"
    "msg.txt_add"               = "इस TXT रिकॉर्ड को अपने डोमेन DNS में जोड़ें:"
    "msg.txt_type"              = "प्रकार: TXT"
    "msg.txt_host"              = "होस्ट: @"
    "msg.txt_value"             = "मान: ZONELY-{0}"
    "msg.txt_added"             = "क्या आपने TXT रिकॉर्ड जोड़ा है?"
    "msg.verifying"             = "सत्यापन हो रहा है..."
    "msg.txt_verified"          = "TXT सत्यापित!"
    "msg.txt_failed"            = "TXT सत्यापन विफल।"
    "msg.retry_verify"          = "सत्यापन पुनः प्रयास करें?"
    "msg.domain_updated"        = "डोमेन सफलतापूर्वक अपडेट किया गया।"
    "msg.domain_update_fail"    = "डोमेन अपडेट करने में विफल।"
    "msg.setup_starting"        = "ऑटो सेटअप शुरू हो रहा है..."
    "msg.setup_finished"        = "सेटअप प्रक्रिया समाप्त हो गई।"
    "msg.setup_start_fail"      = "ऑटो सेटअप शुरू नहीं कर सका।"
    "msg.sql_ok"                = "SQL डंप यहाँ डाउनलोड किया गया: {0}"
    "msg.sql_empty"             = "SQL डंप विफल (खाली फ़ाइल)।"
    "msg.sql_error"             = "SQL डंप त्रुटि: {0}"
    "msg.authme_build_fail"     = "AuthMe कॉन्फ़िगरेशन नहीं बना सका।"
    "msg.authme_saved"          = "AuthMe कॉन्फ़िगरेशन यहाँ सहेजा गया: {0}"
    "msg.authme_info_fail"      = "कॉन्फ़िगरेशन के लिए लाइसेंस जानकारी प्राप्त नहीं कर सका।"
    "msg.db_info"               = "डेटाबेस जानकारी:"
    "msg.db_host_line"          = "होस्ट: {0}"
    "msg.db_port_line"          = "पोर्ट: {0}"
    "msg.db_user_line"          = "उपयोगकर्ता: {0}"
    "msg.db_pass_line"          = "पासवर्ड: {0}"
    "msg.db_name_line"          = "DB नाम: {0}"
    "msg.dns_required"          = "DNS सत्यापन आवश्यक"
    "msg.dns_add"               = "कृपया इन रिकॉर्ड्स को अपने DNS पैनल में जोड़ें:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (प्रॉक्सी सक्षम)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (प्रॉक्सी सक्षम)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "क्या आपने DNS रिकॉर्ड जोड़े हैं?"
    "msg.dns_failed"            = "सत्यापन विफल। अपना DNS जांचें।"
    "msg.retry"                 = "पुनः प्रयास करें?"
    "msg.creating_license"      = "लाइसेंस बना रहा है..."
    "msg.license_purchased"     = "लाइसेंस सफलतापूर्वक खरीदा गया!"
    "msg.starting_initial"      = "प्रारंभिक सेटअप शुरू हो रहा है..."
    "msg.license_setup_started" = "लाइसेंस सेटअप शुरू हो गया। यह ~30 मिनट में तैयार हो जाएगा।"
    "msg.purchase_failed"       = "खरीद विफल।"
    "msg.discord_token_missing" = "rememberMe टोकन नहीं मिला। कृपया पहले लॉग इन करें।"
    "msg.discord_opening"       = "डिस्कॉर्ड सत्यापन खोल रहा है: {0}"
    "msg.browser_open_fail"     = "ब्राउज़र नहीं खोल सका।"
    "msg.discord_opened"        = "डिस्कॉर्ड सत्यापन खुल गया। पूरा होने पर Enter दबाएं..."
    "msg.fatal_error"           = "गंभीर त्रुटि: {0}"
    "msg.no_licenses"           = "कोई लाइसेंस नहीं मिला।"
    "msg.licenses_header"       = "-- आपके लाइसेंस --"
    "msg.license_line"          = "| डोमेन: {0} | समाप्ति: {1}"
    "msg.setup_wait"            = "सेटअप शुरू हो गया। प्रगति की प्रतीक्षा कर रहा है..."
    "msg.setup_timeout"         = "स्थापना का समय समाप्त हो सकता है।"
    "label.setup"               = "सेटअप"
    "menu.welcome"              = "स्वागत है! कृपया लॉगिन करें या पंजीकरण करें।"
    "menu.login"                = "लॉगिन"
    "menu.register"             = "पंजीकरण"
    "menu.exit"                 = "बाहर निकलें"
    "menu.main"                 = "मुख्य मेनू"
    "menu.list"                 = "लाइसेंस सूची"
    "menu.details"              = "लाइसेंस विवरण देखें"
    "menu.update_domain"        = "डोमेन अपडेट करें"
    "menu.autosetup"            = "ऑटो सेटअप शुरू करें"
    "menu.sqldump"              = "SQL डंप डाउनलोड करें"
    "menu.authme"               = "AuthMe कॉन्फ़िगरेशन जनरेट करें"
    "menu.dbinfo"               = "DB क्रेडेंशियल देखें"
    "menu.buy"                  = "नया लाइसेंस खरीदें"
    "menu.discord"              = "डिस्कॉर्ड रोल सत्यापित करें"
    "menu.logout"               = "लॉगआउट"
}

$script:Translations["hu_HU"] = @{
    "ui.select_language"        = "Nyelv kiválasztása"
    "ui.use_arrows"             = "Használd a FEL/LE nyilakat a navigáláshoz, ENTER a kiválasztáshoz."
    "ui.loading"                = "Betöltés, kérlek várj..."
    "header.tagline1"           = "Erős, biztonságos és skálázható infrastruktúra modern projektekhez."
    "header.tagline2"           = "Játék, licencelés, hosting, integrációk és kezelés egy helyen."
    "header.website"            = "Weboldal"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (igen/nem): "
    "prompt.press_enter"        = "Nyomj Enter-t a folytatáshoz..."
    "prompt.press_enter_done"   = "Nyomj Enter-t ha kész..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Jelszó"
    "prompt.first_name"         = "Keresztnév"
    "prompt.last_name"          = "Vezetéknév"
    "prompt.confirm_password"   = "Jelszó megerősítése"
    "prompt.license_id"         = "Licenc ID"
    "prompt.license_id_default" = "Licenc ID"
    "prompt.new_domain"         = "Add meg az új domaint"
    "prompt.buy_domain"         = "Add meg a domaint a licenc vásárláshoz"
    "msg.answer_yes_no"         = "Kérlek válaszolj igennel vagy nemmel."
    "msg.base_url_missing"      = "Base URL nincs beállítva. Konfiguráld a BaseUrl/BaseUrlEnc vagy env változókat."
    "msg.load_cookies_fail"     = "Nem sikerült betölteni a sütiket: {0}"
    "msg.save_cookies_fail"     = "Nem sikerült menteni a sütiket: {0}"
    "msg.read_license_fail"     = "Nem sikerült olvasni a licenc adatokat: {0}"
    "msg.save_license_ok"       = "Licenc infó mentve helyileg."
    "msg.save_license_fail"     = "Nem sikerült menteni a licenc adatokat: {0}"
    "msg.current_license"       = "Jelenlegi Licenc Infó:"
    "msg.license_id"            = "- Licenc ID: {0}"
    "msg.domain"                = "- Domain: {0}"
    "msg.expiry"                = "- Lejárati dátum: {0}"
    "msg.db_host"               = "- DB Host: {0}"
    "msg.db_port"               = "- DB Port: {0}"
    "msg.db_user"               = "- DB Felhasználó: {0}"
    "msg.db_pass"               = "- DB Jelszó: {0}"
    "msg.db_name"               = "- DB Név: {0}"
    "msg.cloudflare"            = "Cloudflare észlelve (CSRF oldal)."
    "prompt.cookie_header"      = "Kérlek add meg a böngésző Süti Fejlécét (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Nem sikerült lekérni a CSRF tokent. Hiba: {0}"
    "msg.login_success"         = "Sikeres bejelentkezés."
    "msg.login_failed"          = "Sikertelen bejelentkezés."
    "msg.login_2fa"             = "Kétfaktoros hitelesítés szükséges. Kérlek fejezd be a bejelentkezést a weboldalon."
    "msg.unexpected_response"   = "Váratlan válasz a szervertől."
    "msg.register_success"      = "Sikeres regisztráció."
    "msg.register_failed"       = "Sikertelen regisztráció."
    "msg.register_mismatch"     = "A jelszavak nem egyeznek."
    "msg.register_auto"         = "Sikeres regisztráció! Automatikusan bejelentkezve."
    "msg.logged_out"            = "Kijelentkezve."
    "msg.list_fail"             = "Nem sikerült lekérni a licenc listát. A munkamenet lejárt lehet."
    "msg.invalid_license"       = "Ez nem egy érvényes Licenc ID."
    "msg.license_detail_fail"   = "Nem sikerült lekérni a licenc részleteket."
    "msg.invalid_domain"        = "Érvénytelen domain név."
    "msg.txt_required"          = "TXT Ellenőrzés Szükséges:"
    "msg.txt_add"               = "Add hozzá ezt a TXT rekordot a domain DNS-éhez:"
    "msg.txt_type"              = "Típus: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Érték: ZONELY-{0}"
    "msg.txt_added"             = "Hozzáadtad a TXT rekordot?"
    "msg.verifying"             = "Ellenőrzés..."
    "msg.txt_verified"          = "TXT Ellenőrizve!"
    "msg.txt_failed"            = "TXT ellenőrzés sikertelen."
    "msg.retry_verify"          = "Újrapróbálod az ellenőrzést?"
    "msg.domain_updated"        = "Domain sikeresen frissítve."
    "msg.domain_update_fail"    = "Nem sikerült frissíteni a domaint."
    "msg.setup_starting"        = "Auto Setup indítása..."
    "msg.setup_finished"        = "Telepítési folyamat befejeződött."
    "msg.setup_start_fail"      = "Nem sikerült elindítani az auto setup-ot."
    "msg.sql_ok"                = "SQL dump letöltve ide: {0}"
    "msg.sql_empty"             = "SQL dump sikertelen (üres fájl)."
    "msg.sql_error"             = "SQL dump hiba: {0}"
    "msg.authme_build_fail"     = "Nem sikerült felépíteni az AuthMe config-ot."
    "msg.authme_saved"          = "AuthMe config mentve ide: {0}"
    "msg.authme_info_fail"      = "Nem sikerült lekérni a licenc infót a config-hoz."
    "msg.db_info"               = "Adatbázis Információk:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Port: {0}"
    "msg.db_user_line"          = "Felhasználó: {0}"
    "msg.db_pass_line"          = "Jelszó: {0}"
    "msg.db_name_line"          = "DB Név: {0}"
    "msg.dns_required"          = "DNS Ellenőrzés Szükséges"
    "msg.dns_add"               = "Kérlek add hozzá ezeket a rekordokat a DNS panelhez:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Engedélyezve)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Engedélyezve)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Hozzáadtad a DNS rekordokat?"
    "msg.dns_failed"            = "Ellenőrzés sikertelen. Ellenőrizd a DNS-t."
    "msg.retry"                 = "Újrapróbálás?"
    "msg.creating_license"      = "Licenc létrehozása..."
    "msg.license_purchased"     = "Licenc sikeresen megvásárolva!"
    "msg.starting_initial"      = "Kézdeti setup indítása..."
    "msg.license_setup_started" = "Licenc setup elindult. Kb. 30 perc múlva kész."
    "msg.purchase_failed"       = "Vásárlás sikertelen."
    "msg.discord_token_missing" = "rememberMe token nem található. Kérlek jelentkezz be először."
    "msg.discord_opening"       = "Discord ellenőrzés megnyitása: {0}"
    "msg.browser_open_fail"     = "Nem sikerült megnyitni a böngészőt."
    "msg.discord_opened"        = "Discord ellenőrzés megnyitva. Nyomj Enter-t ha kész..."
    "msg.fatal_error"           = "Végzetes Hiba: {0}"
    "msg.no_licenses"           = "Nincs licenc."
    "msg.licenses_header"       = "-- Licenceid --"
    "msg.license_line"          = "| Domain: {0} | Lejárat: {1}"
    "msg.setup_wait"            = "Setup elindult. Várakozás a haladásra..."
    "msg.setup_timeout"         = "A telepítés lehet, hogy időtúllépésbe futott."
    "label.setup"               = "Setup"
    "menu.welcome"              = "Üdvözöljük! Kérlek jelentkezz be vagy regisztrálj."
    "menu.login"                = "Bejelentkezés"
    "menu.register"             = "Regisztráció"
    "menu.exit"                 = "Kilépés"
    "menu.main"                 = "Főmenü"
    "menu.list"                 = "Licencek Listázása"
    "menu.details"              = "Licenc Részletek"
    "menu.update_domain"        = "Domain Frissítése"
    "menu.autosetup"            = "Auto Setup Indítása"
    "menu.sqldump"              = "SQL Dump Letöltése"
    "menu.authme"               = "AuthMe Config Generálása"
    "menu.dbinfo"               = "DB Adatok Megtekintése"
    "menu.buy"                  = "Új Licenc Vásárlása"
    "menu.discord"              = "Discord Szerep Ellenőrzés"
    "menu.logout"               = "Kijelentkezés"
}

$script:Translations["it_IT"] = @{
    "ui.select_language"        = "Seleziona Lingua"
    "ui.use_arrows"             = "Usa le frecce SU/GIU per navigare, INVIO per selezionare."
    "ui.loading"                = "Caricamento, attendere prego..."
    "header.tagline1"           = "Infrastruttura potente, sicura e scalabile per progetti moderni."
    "header.tagline2"           = "Giochi, licenze, hosting, integrazioni e gestione in un unico posto."
    "header.website"            = "Sito Web"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (si/no): "
    "prompt.press_enter"        = "Premi Invio per continuare..."
    "prompt.press_enter_done"   = "Premi Invio quando completato..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Password"
    "prompt.first_name"         = "Nome"
    "prompt.last_name"          = "Cognome"
    "prompt.confirm_password"   = "Conferma Password"
    "prompt.license_id"         = "ID Licenza"
    "prompt.license_id_default" = "ID Licenza"
    "prompt.new_domain"         = "Inserisci Nuovo Dominio"
    "prompt.buy_domain"         = "Inserisci Dominio per Comprare Licenza"
    "msg.answer_yes_no"         = "Per favore rispondi si o no."
    "msg.base_url_missing"      = "Base URL non impostato. Configura BaseUrl/BaseUrlEnc o env vars."
    "msg.load_cookies_fail"     = "Impossibile caricare i cookie: {0}"
    "msg.save_cookies_fail"     = "Impossibile salvare i cookie: {0}"
    "msg.read_license_fail"     = "Impossibile leggere i dati della licenza: {0}"
    "msg.save_license_ok"       = "Info licenza salvate localmente."
    "msg.save_license_fail"     = "Impossibile salvare i dati della licenza: {0}"
    "msg.current_license"       = "Info Licenza Attuale:"
    "msg.license_id"            = "- ID Licenza: {0}"
    "msg.domain"                = "- Dominio: {0}"
    "msg.expiry"                = "- Scadenza: {0}"
    "msg.db_host"               = "- Host DB: {0}"
    "msg.db_port"               = "- Porta DB: {0}"
    "msg.db_user"               = "- Utente DB: {0}"
    "msg.db_pass"               = "- Password DB: {0}"
    "msg.db_name"               = "- Nome DB: {0}"
    "msg.cloudflare"            = "Cloudflare rilevato (pagina CSRF)."
    "prompt.cookie_header"      = "Inserisci Header Cookie del Browser (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Impossibile ottenere token CSRF. Errore: {0}"
    "msg.login_success"         = "Login riuscito."
    "msg.login_failed"          = "Login fallito."
    "msg.login_2fa"             = "Autenticazione a due fattori richiesta. Completa il login sul sito web."
    "msg.unexpected_response"   = "Risposta imprevista dal server."
    "msg.register_success"      = "Registrazione riuscita."
    "msg.register_failed"       = "Registrazione fallita."
    "msg.register_mismatch"     = "Le password non corrispondono."
    "msg.register_auto"         = "Registrazione riuscita! Login automatico."
    "msg.logged_out"            = "Disconnesso."
    "msg.list_fail"             = "Impossibile recuperare la lista licenze. La sessione potrebbe essere scaduta."
    "msg.invalid_license"       = "Non e un ID Licenza valido."
    "msg.license_detail_fail"   = "Impossibile recuperare i dettagli della licenza."
    "msg.invalid_domain"        = "Nome dominio non valido."
    "msg.txt_required"          = "Verifica TXT Richiesta:"
    "msg.txt_add"               = "Aggiungi questo record TXT al DNS del dominio:"
    "msg.txt_type"              = "Tipo: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Valore: ZONELY-{0}"
    "msg.txt_added"             = "Hai aggiunto il record TXT?"
    "msg.verifying"             = "Verifica in corso..."
    "msg.txt_verified"          = "TXT Verificato!"
    "msg.txt_failed"            = "Verifica TXT fallita."
    "msg.retry_verify"          = "Riprovare verifica?"
    "msg.domain_updated"        = "Dominio aggiornato con successo."
    "msg.domain_update_fail"    = "Impossibile aggiornare il dominio."
    "msg.setup_starting"        = "Avvio Auto Setup..."
    "msg.setup_finished"        = "Processo di installazione terminato."
    "msg.setup_start_fail"      = "Impossibile avviare auto setup."
    "msg.sql_ok"                = "Dump SQL scaricato in: {0}"
    "msg.sql_empty"             = "Dump SQL fallito (file vuoto)."
    "msg.sql_error"             = "Errore Dump SQL: {0}"
    "msg.authme_build_fail"     = "Impossibile costruire config AuthMe."
    "msg.authme_saved"          = "Config AuthMe salvata in: {0}"
    "msg.authme_info_fail"      = "Impossibile recuperare info licenza per la config."
    "msg.db_info"               = "Informazioni Database:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Porta: {0}"
    "msg.db_user_line"          = "Utente: {0}"
    "msg.db_pass_line"          = "Password: {0}"
    "msg.db_name_line"          = "Nome DB: {0}"
    "msg.dns_required"          = "Verifica DNS Richiesta"
    "msg.dns_add"               = "Aggiungi questi record al tuo pannello DNS:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Attivo)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Attivo)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Hai aggiunto i record DNS?"
    "msg.dns_failed"            = "Verifica fallita. Controlla il tuo DNS."
    "msg.retry"                 = "Riprovare?"
    "msg.creating_license"      = "Creazione licenza..."
    "msg.license_purchased"     = "Licenza acquistata con successo!"
    "msg.starting_initial"      = "Avvio configurazione iniziale..."
    "msg.license_setup_started" = "Setup licenza avviato. Pronto in ~30 minuti."
    "msg.purchase_failed"       = "Acquisto fallito."
    "msg.discord_token_missing" = "Token rememberMe non trovato. Accedi prima."
    "msg.discord_opening"       = "Apertura verifica Discord: {0}"
    "msg.browser_open_fail"     = "Impossibile aprire il browser."
    "msg.discord_opened"        = "Verifica Discord aperta. Premi Invio quando completato..."
    "msg.fatal_error"           = "Errore Fatale: {0}"
    "msg.no_licenses"           = "Nessuna licenza trovata."
    "msg.licenses_header"       = "-- Le Tue Licenze --"
    "msg.license_line"          = "| Dominio: {0} | Scadenza: {1}"
    "msg.setup_wait"            = "Setup avviato. In attesa di progresso..."
    "msg.setup_timeout"         = "L'installazione potrebbe essere in timeout."
    "label.setup"               = "Setup"
    "menu.welcome"              = "Benvenuto! Accedi o registrati."
    "menu.login"                = "Accedi"
    "menu.register"             = "Registrati"
    "menu.exit"                 = "Esci"
    "menu.main"                 = "Menu Principale"
    "menu.list"                 = "Lista Licenze"
    "menu.details"              = "Dettagli Licenza"
    "menu.update_domain"        = "Aggiorna Dominio"
    "menu.autosetup"            = "Avvia Auto Setup"
    "menu.sqldump"              = "Scarica Dump SQL"
    "menu.authme"               = "Genera Config AuthMe"
    "menu.dbinfo"               = "Credenziali DB"
    "menu.buy"                  = "Compra Nuova Licenza"
    "menu.discord"              = "Verifica Ruolo Discord"
    "menu.logout"               = "Disconnetti"
}

$script:Translations["ja_JP"] = @{
    "ui.select_language"        = "言語を選択"
    "ui.use_arrows"             = "上/下矢印キーで移動, ENTER で選択。"
    "ui.loading"                = "読み込み中、お待ちください..."
    "header.tagline1"           = "現代のプロジェクトのための強力で安全、スケーラブルなインフラストラクチャ。"
    "header.tagline2"           = "ゲーム、ライセンス、ホスティング、統合、管理をすべて一箇所で。"
    "header.website"            = "ウェブサイト"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (はい/いいえ): "
    "prompt.press_enter"        = "Enterキーを押して続行..."
    "prompt.press_enter_done"   = "完了したらEnterキーを押してください..."
    "prompt.email"              = "メールアドレス"
    "prompt.password"           = "パスワード"
    "prompt.first_name"         = "名"
    "prompt.last_name"          = "姓"
    "prompt.confirm_password"   = "パスワード確認"
    "prompt.license_id"         = "ライセンスID"
    "prompt.license_id_default" = "ライセンスID"
    "prompt.new_domain"         = "新しいドメイン名を入力"
    "prompt.buy_domain"         = "ライセンス購入用ドメインを入力"
    "msg.answer_yes_no"         = "はい または いいえ で答えてください。"
    "msg.base_url_missing"      = "Base URL が設定されていません。BaseUrl/BaseUrlEnc または環境変数を設定してください。"
    "msg.load_cookies_fail"     = "Cookieの読み込みに失敗しました: {0}"
    "msg.save_cookies_fail"     = "Cookieの保存に失敗しました: {0}"
    "msg.read_license_fail"     = "ライセンスデータの読み込みに失敗しました: {0}"
    "msg.save_license_ok"       = "ライセンス情報がローカルに保存されました。"
    "msg.save_license_fail"     = "ライセンスデータの保存に失敗しました: {0}"
    "msg.current_license"       = "現在のライセンス情報:"
    "msg.license_id"            = "- ライセンスID: {0}"
    "msg.domain"                = "- ドメイン: {0}"
    "msg.expiry"                = "- 有効期限: {0}"
    "msg.db_host"               = "- DBホスト: {0}"
    "msg.db_port"               = "- DBポート: {0}"
    "msg.db_user"               = "- DBユーザー: {0}"
    "msg.db_pass"               = "- DBパスワード: {0}"
    "msg.db_name"               = "- DB名: {0}"
    "msg.cloudflare"            = "Cloudflare が検出されました (CSRFページ)。"
    "prompt.cookie_header"      = "ブラウザのCookieヘッダーを入力してください (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "CSRFトークンの取得に失敗しました。エラー: {0}"
    "msg.login_success"         = "ログイン成功。"
    "msg.login_failed"          = "ログイン失敗。"
    "msg.login_2fa"             = "二要素認証が必要です。ウェブサイトでログインを完了してください。"
    "msg.unexpected_response"   = "サーバーからの予期しない応答。"
    "msg.register_success"      = "登録成功。"
    "msg.register_failed"       = "登録失敗。"
    "msg.register_mismatch"     = "パスワードが一致しません。"
    "msg.register_auto"         = "登録成功！自動的にログインしました。"
    "msg.logged_out"            = "ログアウトしました。"
    "msg.list_fail"             = "ライセンスリストの取得に失敗しました。セッションが期限切れの可能性があります。"
    "msg.invalid_license"       = "無効なライセンスIDです。"
    "msg.license_detail_fail"   = "ライセンス詳細を取得できませんでした。"
    "msg.invalid_domain"        = "無効なドメイン名です。"
    "msg.txt_required"          = "TXT認証が必要です:"
    "msg.txt_add"               = "ドメインDNSに以下のTXTレコードを追加してください:"
    "msg.txt_type"              = "タイプ: TXT"
    "msg.txt_host"              = "ホスト: @"
    "msg.txt_value"             = "値: ZONELY-{0}"
    "msg.txt_added"             = "TXTレコードを追加しましたか？"
    "msg.verifying"             = "確認中..."
    "msg.txt_verified"          = "TXT確認完了！"
    "msg.txt_failed"            = "TXT確認失敗。"
    "msg.retry_verify"          = "再試行しますか？"
    "msg.domain_updated"        = "ドメインが更新されました。"
    "msg.domain_update_fail"    = "ドメインの更新に失敗しました。"
    "msg.setup_starting"        = "自動セットアップ開始中..."
    "msg.setup_finished"        = "セットアップ処理完了。"
    "msg.setup_start_fail"      = "自動セットアップを開始できませんでした。"
    "msg.sql_ok"                = "SQLダンプをダウンロードしました: {0}"
    "msg.sql_empty"             = "SQLダンプ失敗 (空のファイル)。"
    "msg.sql_error"             = "SQLダンプエラー: {0}"
    "msg.authme_build_fail"     = "AuthMe設定を作成できませんでした。"
    "msg.authme_saved"          = "AuthMe設定を保存しました: {0}"
    "msg.authme_info_fail"      = "設定用のライセンス情報を取得できませんでした。"
    "msg.db_info"               = "データベース情報:"
    "msg.db_host_line"          = "ホスト: {0}"
    "msg.db_port_line"          = "ポート: {0}"
    "msg.db_user_line"          = "ユーザー: {0}"
    "msg.db_pass_line"          = "パスワード: {0}"
    "msg.db_name_line"          = "DB名: {0}"
    "msg.dns_required"          = "DNS検証が必要です"
    "msg.dns_add"               = "DNSパネルに以下のレコードを追加してください:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (プロキシ有効)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (プロキシ有効)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "DNSレコードを追加しましたか？"
    "msg.dns_failed"            = "検証失敗。DNSを確認してください。"
    "msg.retry"                 = "再試行？"
    "msg.creating_license"      = "ライセンス作成中..."
    "msg.license_purchased"     = "ライセンス購入成功！"
    "msg.starting_initial"      = "初期設定を開始中..."
    "msg.license_setup_started" = "ライセンス設定を開始しました。約30分で準備完了します。"
    "msg.purchase_failed"       = "購入失敗。"
    "msg.discord_token_missing" = "rememberMeトークンが見つかりません。先にログインしてください。"
    "msg.discord_opening"       = "Discord検証を開いています: {0}"
    "msg.browser_open_fail"     = "ブラウザを開けませんでした。"
    "msg.discord_opened"        = "Discord検証を開きました。完了したらEnterキーを押してください..."
    "msg.fatal_error"           = "致命的なエラー: {0}"
    "msg.no_licenses"           = "ライセンスが見つかりません。"
    "msg.licenses_header"       = "-- あなたのライセンス --"
    "msg.license_line"          = "| ドメイン: {0} | 有効期限: {1}"
    "msg.setup_wait"            = "セットアップ開始。進行を待機中..."
    "msg.setup_timeout"         = "インストールがタイムアウトしている可能性があります。"
    "label.setup"               = "セットアップ"
    "menu.welcome"              = "ようこそ！ログインまたは登録してください。"
    "menu.login"                = "ログイン"
    "menu.register"             = "登録"
    "menu.exit"                 = "終了"
    "menu.main"                 = "メインメニュー"
    "menu.list"                 = "ライセンス一覧"
    "menu.details"              = "ライセンス詳細"
    "menu.update_domain"        = "ドメイン更新"
    "menu.autosetup"            = "自動セットアップ開始"
    "menu.sqldump"              = "SQLダンプ ダウンロード"
    "menu.authme"               = "AuthMe設定 生成"
    "menu.dbinfo"               = "DB認証情報"
    "menu.buy"                  = "新規ライセンス購入"
    "menu.discord"              = "Discordロール確認"
    "menu.logout"               = "ログアウト"
}

$script:Translations["nb_NO"] = @{
    "ui.select_language"        = "Velg Språk"
    "ui.use_arrows"             = "Bruk OPP/NED pilene for å navigere, ENTER for å velge."
    "ui.loading"                = "Laster, vennligst vent..."
    "header.tagline1"           = "Kraftig, sikker og skalerbar infrastruktur for moderne prosjekter."
    "header.tagline2"           = "Spill, lisensiering, hosting, integrasjoner og administrasjon på ett sted."
    "header.website"            = "Nettsted"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (ja/nei): "
    "prompt.press_enter"        = "Trykk Enter for å fortsette..."
    "prompt.press_enter_done"   = "Trykk Enter når ferdig..."
    "prompt.email"              = "E-post"
    "prompt.password"           = "Passord"
    "prompt.first_name"         = "Fornavn"
    "prompt.last_name"          = "Etternavn"
    "prompt.confirm_password"   = "Bekreft Passord"
    "prompt.license_id"         = "Lisens-ID"
    "prompt.license_id_default" = "Lisens-ID"
    "prompt.new_domain"         = "Skriv inn nytt domenenavn"
    "prompt.buy_domain"         = "Skriv inn domene for å kjøpe lisens"
    "msg.answer_yes_no"         = "Vennligst svar ja eller nei."
    "msg.base_url_missing"      = "Base URL ikke satt. Konfigurer BaseUrl/BaseUrlEnc eller miljøvariabler."
    "msg.load_cookies_fail"     = "Kunne ikke laste informasjonskapsler: {0}"
    "msg.save_cookies_fail"     = "Kunne ikke lagre informasjonskapsler: {0}"
    "msg.read_license_fail"     = "Kunne ikke lese lisensdata: {0}"
    "msg.save_license_ok"       = "Lisensinfo lagret lokalt."
    "msg.save_license_fail"     = "Kunne ikke lagre lisensdata: {0}"
    "msg.current_license"       = "Gjeldende Lisensinfo:"
    "msg.license_id"            = "- Lisens-ID: {0}"
    "msg.domain"                = "- Domene: {0}"
    "msg.expiry"                = "- Utløpsdato: {0}"
    "msg.db_host"               = "- DB Vert: {0}"
    "msg.db_port"               = "- DB Port: {0}"
    "msg.db_user"               = "- DB Bruker: {0}"
    "msg.db_pass"               = "- DB Passord: {0}"
    "msg.db_name"               = "- DB Navn: {0}"
    "msg.cloudflare"            = "Cloudflare oppdaget (CSRF side)."
    "prompt.cookie_header"      = "Vennligst skriv inn nettleserens informasjonskapsel-overskrift (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Kunne ikke hente CSRF-token. Feil: {0}"
    "msg.login_success"         = "Innlogging vellykket."
    "msg.login_failed"          = "Innlogging mislyktes."
    "msg.login_2fa"             = "To-faktor autentisering kreves. Vennligst fullfør innlogging på nettstedet."
    "msg.unexpected_response"   = "Uventet respons fra serveren."
    "msg.register_success"      = "Registrering vellykket."
    "msg.register_failed"       = "Registrering mislyktes."
    "msg.register_mismatch"     = "Passordene samsvarer ikke."
    "msg.register_auto"         = "Registrering vellykket! Logget inn automatisk."
    "msg.logged_out"            = "Logget ut."
    "msg.list_fail"             = "Kunne ikke hente lisensliste. Sesjonen kan ha utløpt."
    "msg.invalid_license"       = "Det er ikke en gyldig Lisens-ID."
    "msg.license_detail_fail"   = "Kunne ikke hente lisensdetaljer."
    "msg.invalid_domain"        = "Ugyldig domenenavn."
    "msg.txt_required"          = "TXT Verifisering Kreves:"
    "msg.txt_add"               = "Legg til denne TXT-oppføringen i domenets DNS:"
    "msg.txt_type"              = "Type: TXT"
    "msg.txt_host"              = "Vert: @"
    "msg.txt_value"             = "Verdi: ZONELY-{0}"
    "msg.txt_added"             = "Har du lagt til TXT-oppføringen?"
    "msg.verifying"             = "Verifiserer..."
    "msg.txt_verified"          = "TXT Verifisert!"
    "msg.txt_failed"            = "TXT verifisering mislyktes."
    "msg.retry_verify"          = "Prøv verifisering på nytt?"
    "msg.domain_updated"        = "Domenet ble oppdatert."
    "msg.domain_update_fail"    = "Kunne ikke oppdatere domenet."
    "msg.setup_starting"        = "Starter Auto Setup..."
    "msg.setup_finished"        = "Installasjonsprosessen er ferdig."
    "msg.setup_start_fail"      = "Kunne ikke starte auto setup."
    "msg.sql_ok"                = "SQL dump lastet ned til: {0}"
    "msg.sql_empty"             = "SQL dump mislyktes (tom fil)."
    "msg.sql_error"             = "SQL dump feil: {0}"
    "msg.authme_build_fail"     = "Kunne ikke bygge AuthMe-konfigurasjon."
    "msg.authme_saved"          = "AuthMe-konfigurasjon lagret til: {0}"
    "msg.authme_info_fail"      = "Kunne ikke hente lisensinfo for konfigurasjon."
    "msg.db_info"               = "Databaseinformasjon:"
    "msg.db_host_line"          = "Vert: {0}"
    "msg.db_port_line"          = "Port: {0}"
    "msg.db_user_line"          = "Bruker: {0}"
    "msg.db_pass_line"          = "Passord: {0}"
    "msg.db_name_line"          = "DB Navn: {0}"
    "msg.dns_required"          = "DNS Verifisering Kreves"
    "msg.dns_add"               = "Vennligst legg til disse oppføringene i DNS-panelet ditt:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Aktivert)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Aktivert)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Har du lagt til DNS-oppføringene?"
    "msg.dns_failed"            = "Verifisering mislyktes. Sjekk DNS-en din."
    "msg.retry"                 = "Prøve på nytt?"
    "msg.creating_license"      = "Oppretter lisens..."
    "msg.license_purchased"     = "Lisens kjøpt vellykket!"
    "msg.starting_initial"      = "Starter initiell oppsett..."
    "msg.license_setup_started" = "Lisens-oppsett startet. Det vil være klart om ~30 minutter."
    "msg.purchase_failed"       = "Kjøp mislyktes."
    "msg.discord_token_missing" = "rememberMe-token ikke funnet. Vennligst logg inn først."
    "msg.discord_opening"       = "Åpner Discord-verifisering: {0}"
    "msg.browser_open_fail"     = "Kunne ikke åpne nettleseren."
    "msg.discord_opened"        = "Discord-verifisering åpnet. Trykk Enter når ferdig..."
    "msg.fatal_error"           = "Fatal Feil: {0}"
    "msg.no_licenses"           = "Ingen lisenser funnet."
    "msg.licenses_header"       = "-- Dine Lisenser --"
    "msg.license_line"          = "| Domene: {0} | Utløp: {1}"
    "msg.setup_wait"            = "Oppsett startet. Venter på fremdrift..."
    "msg.setup_timeout"         = "Installasjonen kan ta for lang tid."
    "label.setup"               = "Oppsett"
    "menu.welcome"              = "Velkommen! Vennligst logg inn eller registrer deg."
    "menu.login"                = "Logg Inn"
    "menu.register"             = "Registrer"
    "menu.exit"                 = "Avslutt"
    "menu.main"                 = "Hovedmeny"
    "menu.list"                 = "Vis Lisenser"
    "menu.details"              = "Vis Lisensdetaljer"
    "menu.update_domain"        = "Oppdater Domene"
    "menu.autosetup"            = "Start Auto Setup"
    "menu.sqldump"              = "Last Ned SQL Dump"
    "menu.authme"               = "Generer AuthMe Konfig"
    "menu.dbinfo"               = "Vis DB-legitimasjon"
    "menu.buy"                  = "Kjøp Ny Lisens"
    "menu.discord"              = "Verifiser Discord-rolle"
    "menu.logout"               = "Logg Ut"
}

$script:Translations["nl_NL"] = @{
    "ui.select_language"        = "Selecteer Taal"
    "ui.use_arrows"             = "Gebruik OMHOOG/OMLAAG pijlen om te navigeren, ENTER om te selecteren."
    "ui.loading"                = "Laden, een ogenblik geduld..."
    "header.tagline1"           = "Krachtige, veilige en schaalbare infrastructuur voor moderne projecten."
    "header.tagline2"           = "Games, licenties, hosting, integraties en beheer op één plek."
    "header.website"            = "Website"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (ja/nee): "
    "prompt.press_enter"        = "Druk op Enter om door te gaan..."
    "prompt.press_enter_done"   = "Druk op Enter wanneer voltooid..."
    "prompt.email"              = "E-mail"
    "prompt.password"           = "Wachtwoord"
    "prompt.first_name"         = "Voornaam"
    "prompt.last_name"          = "Achternaam"
    "prompt.confirm_password"   = "Bevestig Wachtwoord"
    "prompt.license_id"         = "Licentie-ID"
    "prompt.license_id_default" = "Licentie-ID"
    "prompt.new_domain"         = "Voer nieuwe domeinnaam in"
    "prompt.buy_domain"         = "Voer domein in om licentie te kopen"
    "msg.answer_yes_no"         = "Antwoord alstublieft met ja of nee."
    "msg.base_url_missing"      = "Basis-URL niet ingesteld. Configureer BaseUrl/BaseUrlEnc of omgevingsvariabelen."
    "msg.load_cookies_fail"     = "Kon cookies niet laden: {0}"
    "msg.save_cookies_fail"     = "Kon cookies niet opslaan: {0}"
    "msg.read_license_fail"     = "Kon licentiegegevens niet lezen: {0}"
    "msg.save_license_ok"       = "Licentie-informatie lokaal opgeslagen."
    "msg.save_license_fail"     = "Kon licentiegegevens niet opslaan: {0}"
    "msg.current_license"       = "Huidige Licentie-informatie:"
    "msg.license_id"            = "- Licentie-ID: {0}"
    "msg.domain"                = "- Domein: {0}"
    "msg.expiry"                = "- Vervaldatum: {0}"
    "msg.db_host"               = "- DB Host: {0}"
    "msg.db_port"               = "- DB Poort: {0}"
    "msg.db_user"               = "- DB Gebruiker: {0}"
    "msg.db_pass"               = "- DB Wachtwoord: {0}"
    "msg.db_name"               = "- DB Naam: {0}"
    "msg.cloudflare"            = "Cloudflare gedetecteerd (CSRF-pagina)."
    "prompt.cookie_header"      = "Voer browser cookie header in (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Kon CSRF-token niet verkrijgen. Fout: {0}"
    "msg.login_success"         = "Inloggen geslaagd."
    "msg.login_failed"          = "Inloggen mislukt."
    "msg.login_2fa"             = "Tweestapsverificatie vereist. Voltooi het inloggen op de website."
    "msg.unexpected_response"   = "Onverwacht antwoord van de server."
    "msg.register_success"      = "Registratie geslaagd."
    "msg.register_failed"       = "Registratie mislukt."
    "msg.register_mismatch"     = "Wachtwoorden komen niet overeen."
    "msg.register_auto"         = "Registratie geslaagd! Automatisch ingelogd."
    "msg.logged_out"            = "Uitgelogd."
    "msg.list_fail"             = "Kon licentielijst niet ophalen. Sessie is mogelijk verlopen."
    "msg.invalid_license"       = "Dat is geen geldige Licentie-ID."
    "msg.license_detail_fail"   = "Kon licentiegegevens niet ophalen."
    "msg.invalid_domain"        = "Ongeldige domeinnaam."
    "msg.txt_required"          = "TXT-verificatie vereist:"
    "msg.txt_add"               = "Voeg dit TXT-record toe aan de DNS van uw domein:"
    "msg.txt_type"              = "Type: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Waarde: ZONELY-{0}"
    "msg.txt_added"             = "Heeft u het TXT-record toegevoegd?"
    "msg.verifying"             = "Verifiëren..."
    "msg.txt_verified"          = "TXT Geverifieerd!"
    "msg.txt_failed"            = "TXT-verificatie mislukt."
    "msg.retry_verify"          = "Verificatie opnieuw proberen?"
    "msg.domain_updated"        = "Domein succesvol bijgewerkt."
    "msg.domain_update_fail"    = "Kon domein niet bijwerken."
    "msg.setup_starting"        = "Auto Setup starten..."
    "msg.setup_finished"        = "Installatieproces voltooid."
    "msg.setup_start_fail"      = "Kon auto setup niet starten."
    "msg.sql_ok"                = "SQL-dump gedownload naar: {0}"
    "msg.sql_empty"             = "SQL-dump mislukt (leeg bestand)."
    "msg.sql_error"             = "Fout bij SQL-dump: {0}"
    "msg.authme_build_fail"     = "Kon AuthMe-configuratie niet bouwen."
    "msg.authme_saved"          = "AuthMe-configuratie opgeslagen in: {0}"
    "msg.authme_info_fail"      = "Kon licentiegegevens voor configuratie niet ophalen."
    "msg.db_info"               = "Database-informatie:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Poort: {0}"
    "msg.db_user_line"          = "Gebruiker: {0}"
    "msg.db_pass_line"          = "Wachtwoord: {0}"
    "msg.db_name_line"          = "DB Naam: {0}"
    "msg.dns_required"          = "DNS-verificatie vereist"
    "msg.dns_add"               = "Voeg deze records toe aan uw DNS-paneel:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Ingeschakeld)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Ingeschakeld)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Heeft u de DNS-records toegevoegd?"
    "msg.dns_failed"            = "Verificatie mislukt. Controleer uw DNS."
    "msg.retry"                 = "Opnieuw proberen?"
    "msg.creating_license"      = "Licentie aanmaken..."
    "msg.license_purchased"     = "Licentie succesvol gekocht!"
    "msg.starting_initial"      = "Eerste installatie starten..."
    "msg.license_setup_started" = "Licentie-installatie gestart. Het zal over ~30 minuten klaar zijn."
    "msg.purchase_failed"       = "Aankoop mislukt."
    "msg.discord_token_missing" = "rememberMe-token niet gevonden. Log eerst in."
    "msg.discord_opening"       = "Discord-verificatie openen: {0}"
    "msg.browser_open_fail"     = "Kon browser niet openen."
    "msg.discord_opened"        = "Discord-verificatie geopend. Druk op Enter wanneer voltooid..."
    "msg.fatal_error"           = "Fatale Fout: {0}"
    "msg.no_licenses"           = "Geen licenties gevonden."
    "msg.licenses_header"       = "-- Uw Licenties --"
    "msg.license_line"          = "| Domein: {0} | Vervalt: {1}"
    "msg.setup_wait"            = "Installatie gestart. Wachten op voortgang..."
    "msg.setup_timeout"         = "De installatie duurt mogelijk te lang."
    "label.setup"               = "Installatie"
    "menu.welcome"              = "Welkom! Log in of registreer."
    "menu.login"                = "Inloggen"
    "menu.register"             = "Registreren"
    "menu.exit"                 = "Afsluiten"
    "menu.main"                 = "Hoofdmenu"
    "menu.list"                 = "Licenties Weergeven"
    "menu.details"              = "Licentiedetails Weergeven"
    "menu.update_domain"        = "Domein Bijwerken"
    "menu.autosetup"            = "Auto Setup Starten"
    "menu.sqldump"              = "SQL Dump Downloaden"
    "menu.authme"               = "AuthMe Config Genereren"
    "menu.dbinfo"               = "DB-inloggegevens Weergeven"
    "menu.buy"                  = "Nieuwe Licentie Kopen"
    "menu.discord"              = "Discord-rol Verifiëren"
    "menu.logout"               = "Uitloggen"
}

$script:Translations["pl_PL"] = @{
    "ui.select_language"        = "Wybierz Jezyk"
    "ui.use_arrows"             = "Uzyj strzalek GORA/DOL do nawigacji, ENTER zeby wybrac."
    "ui.loading"                = "Ladowanie, prosze czekac..."
    "header.tagline1"           = "Potezna, bezpieczna i skalowalna infrastruktura dla nowoczesnych projektow."
    "header.tagline2"           = "Gry, licencjonowanie, hosting, integracje i zarzadzanie w jednym miejscu."
    "header.website"            = "Strona WWW"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (tak/nie): "
    "prompt.press_enter"        = "Wcisnij Enter zeby kontynuowac..."
    "prompt.press_enter_done"   = "Wcisnij Enter gdy skonczysz..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Haslo"
    "prompt.first_name"         = "Imie"
    "prompt.last_name"          = "Nazwisko"
    "prompt.confirm_password"   = "Potwierdz Haslo"
    "prompt.license_id"         = "ID Licencji"
    "prompt.license_id_default" = "ID Licencji"
    "prompt.new_domain"         = "Wpisz Nowa Nazwe Domeny"
    "prompt.buy_domain"         = "Wpisz Domene dla Licencji"
    "msg.answer_yes_no"         = "Prosze odpowiedz tak lub nie."
    "msg.base_url_missing"      = "Base URL nie ustawiony. Skonfiguruj BaseUrl/BaseUrlEnc lub zmienne srodowiskowe."
    "msg.load_cookies_fail"     = "Nie udalo sie zaladowac ciasteczek: {0}"
    "msg.save_cookies_fail"     = "Nie udalo sie zapisac ciasteczek: {0}"
    "msg.read_license_fail"     = "Nie udalo sie odczytac danych licencji: {0}"
    "msg.save_license_ok"       = "Info licencji zapisane lokalnie."
    "msg.save_license_fail"     = "Nie udalo sie zapisac danych licencji: {0}"
    "msg.current_license"       = "Obecne Info Licencji:"
    "msg.license_id"            = "- ID Licencji: {0}"
    "msg.domain"                = "- Domena: {0}"
    "msg.expiry"                = "- Data Wygaśnięcia: {0}"
    "msg.db_host"               = "- DB Host: {0}"
    "msg.db_port"               = "- DB Port: {0}"
    "msg.db_user"               = "- DB Uzytkownik: {0}"
    "msg.db_pass"               = "- DB Haslo: {0}"
    "msg.db_name"               = "- DB Nazwa: {0}"
    "msg.cloudflare"            = "Wykryto Cloudflare (strona CSRF)."
    "prompt.cookie_header"      = "Wpisz Naglowek Cookie Przegladarki (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Nie udalo sie pobrac tokenu CSRF. Blad: {0}"
    "msg.login_success"         = "Logowanie udane."
    "msg.login_failed"          = "Logowanie nieudane."
    "msg.login_2fa"             = "Wymagane uwierzytelnianie dwuskładnikowe. Dokoncz logowanie na stronie."
    "msg.unexpected_response"   = "Nieoczekiwana odpowiedz serwera."
    "msg.register_success"      = "Rejestracja udana."
    "msg.register_failed"       = "Rejestracja nieudana."
    "msg.register_mismatch"     = "Hasla nie pasuja do siebie."
    "msg.register_auto"         = "Rejestracja udana! Zalogowano automatycznie."
    "msg.logged_out"            = "Wylogowano."
    "msg.list_fail"             = "Nie udalo sie pobrac listy licencji. Sesja mogla wygasnac."
    "msg.invalid_license"       = "To nie jest poprawne ID licencji."
    "msg.license_detail_fail"   = "Nie udalo sie pobrac szczegolow licencji."
    "msg.invalid_domain"        = "Nieprawidlowa nazwa domeny."
    "msg.txt_required"          = "Wymagana Weryfikacja TXT:"
    "msg.txt_add"               = "Dodaj ten rekord TXT do DNS domeny:"
    "msg.txt_type"              = "Typ: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Wartosc: ZONELY-{0}"
    "msg.txt_added"             = "Dodales rekord TXT?"
    "msg.verifying"             = "Weryfikacja..."
    "msg.txt_verified"          = "TXT Zweryfikowany!"
    "msg.txt_failed"            = "Weryfikacja TXT nieudana."
    "msg.retry_verify"          = "Sprobowac ponownie?"
    "msg.domain_updated"        = "Domena zaktualizowana pomyslnie."
    "msg.domain_update_fail"    = "Nie udalo sie zaktualizowac domeny."
    "msg.setup_starting"        = "Uruchamianie Auto Setup..."
    "msg.setup_finished"        = "Proces instalacji zakonczony."
    "msg.setup_start_fail"      = "Nie udalo sie uruchomic auto setup."
    "msg.sql_ok"                = "Zrzut SQL pobrany do: {0}"
    "msg.sql_empty"             = "Zrzut SQL nieudany (pusty plik)."
    "msg.sql_error"             = "Blad zrzutu SQL: {0}"
    "msg.authme_build_fail"     = "Nie udalo sie zbudowac konfiguracji AuthMe."
    "msg.authme_saved"          = "Konfiguracja AuthMe zapisana do: {0}"
    "msg.authme_info_fail"      = "Nie udalo sie pobrac info licencji dla konfiguracji."
    "msg.db_info"               = "Informacje o Bazie Danych:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Port: {0}"
    "msg.db_user_line"          = "Uzytkownik: {0}"
    "msg.db_pass_line"          = "Haslo: {0}"
    "msg.db_name_line"          = "Nazwa DB: {0}"
    "msg.dns_required"          = "Wymagana Weryfikacja DNS"
    "msg.dns_add"               = "Dodaj te rekordy do panelu DNS:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Wlaczone)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Wlaczone)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Dodales rekordy DNS?"
    "msg.dns_failed"            = "Weryfikacja nieudana. Sprawdz swoj DNS."
    "msg.retry"                 = "Sprobowac ponownie?"
    "msg.creating_license"      = "Tworzenie licencji..."
    "msg.license_purchased"     = "Licencja zakupiona pomyslnie!"
    "msg.starting_initial"      = "Uruchamianie wstepnej konfiguracji..."
    "msg.license_setup_started" = "Konfiguracja licencji rozpoczeta. Bedzie gotowa za ~30 minut."
    "msg.purchase_failed"       = "Zakup nieudany."
    "msg.discord_token_missing" = "Token rememberMe nie znaleziony. Zaloguj sie najpierw."
    "msg.discord_opening"       = "Otwieranie weryfikacji Discord: {0}"
    "msg.browser_open_fail"     = "Nie udalo sie otworzyc przegladarki."
    "msg.discord_opened"        = "Weryfikacja Discord otwarta. Wcisnij Enter gdy skonczysz..."
    "msg.fatal_error"           = "Blad Krytyczny: {0}"
    "msg.no_licenses"           = "Nie znaleziono licencji."
    "msg.licenses_header"       = "-- Twoje Licencje --"
    "msg.license_line"          = "| Domena: {0} | Wygasa: {1}"
    "msg.setup_wait"            = "Konfiguracja rozpoczeta. Oczekiwanie na postep..."
    "msg.setup_timeout"         = "Instalacja moze trwac zbyt dlugo."
    "label.setup"               = "Konfiguracja"
    "menu.welcome"              = "Witaj! Zaloguj sie lub zarejestruj."
    "menu.login"                = "Zaloguj"
    "menu.register"             = "Zarejestruj"
    "menu.exit"                 = "Wyjscie"
    "menu.main"                 = "Menu Glowne"
    "menu.list"                 = "Lista Licencji"
    "menu.details"              = "Szczegoly Licencji"
    "menu.update_domain"        = "Aktualizuj Domene"
    "menu.autosetup"            = "Start Auto Setup"
    "menu.sqldump"              = "Pobierz Zrzut SQL"
    "menu.authme"               = "Generuj Config AuthMe"
    "menu.dbinfo"               = "Pokaz Dane DB"
    "menu.buy"                  = "Kup Nowa Licencje"
    "menu.discord"              = "Weryfikuj Role Discord"
    "menu.logout"               = "Wyloguj"
}

$script:Translations["pt_BR"] = @{
    "ui.select_language"        = "Selecionar Idioma"
    "ui.use_arrows"             = "Use SETAS CIMA/BAIXO para navegar, ENTER para selecionar."
    "ui.loading"                = "Carregando, por favor aguarde..."
    "header.tagline1"           = "Infraestrutura poderosa, segura e escalavel para projetos modernos."
    "header.tagline2"           = "Jogos, licenciamento, hospedagem, integracoes e gerenciamento em um so lugar."
    "header.website"            = "Site"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (sim/nao): "
    "prompt.press_enter"        = "Pressione Enter para continuar..."
    "prompt.press_enter_done"   = "Pressione Enter quando terminar..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Senha"
    "prompt.first_name"         = "Nome"
    "prompt.last_name"          = "Sobrenome"
    "prompt.confirm_password"   = "Confirmar Senha"
    "prompt.license_id"         = "ID da Licenca"
    "prompt.license_id_default" = "ID da Licenca"
    "prompt.new_domain"         = "Digitar Novo Dominio"
    "prompt.buy_domain"         = "Digitar Dominio para Comprar Licenca"
    "msg.answer_yes_no"         = "Por favor responda sim ou nao."
    "msg.base_url_missing"      = "URL base nao definida. Configure BaseUrl/BaseUrlEnc ou variaveis de ambiente."
    "msg.load_cookies_fail"     = "Falha ao carregar cookies: {0}"
    "msg.save_cookies_fail"     = "Falha ao salvar cookies: {0}"
    "msg.read_license_fail"     = "Falha ao ler dados da licenca: {0}"
    "msg.save_license_ok"       = "Info da licenca salva localmente."
    "msg.save_license_fail"     = "Falha ao salvar dados da licenca: {0}"
    "msg.current_license"       = "Info da Licenca Atual:"
    "msg.license_id"            = "- ID da Licenca: {0}"
    "msg.domain"                = "- Dominio: {0}"
    "msg.expiry"                = "- Data de Expiracao: {0}"
    "msg.db_host"               = "- Host DB: {0}"
    "msg.db_port"               = "- Porta DB: {0}"
    "msg.db_user"               = "- Usuario DB: {0}"
    "msg.db_pass"               = "- Senha DB: {0}"
    "msg.db_name"               = "- Nome DB: {0}"
    "msg.cloudflare"            = "Cloudflare detectado (pagina CSRF)."
    "prompt.cookie_header"      = "Digite o Cabecalho de Cookie do Navegador (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Falha ao obter token CSRF. Erro: {0}"
    "msg.login_success"         = "Login com sucesso."
    "msg.login_failed"          = "Login falhou."
    "msg.login_2fa"             = "Autenticacao de dois fatores necessaria. Complete o login no site."
    "msg.unexpected_response"   = "Resposta inesperada do servidor."
    "msg.register_success"      = "Registro com sucesso."
    "msg.register_failed"       = "Registro falhou."
    "msg.register_mismatch"     = "Senhas nao conferem."
    "msg.register_auto"         = "Registro com sucesso! Logado automaticamente."
    "msg.logged_out"            = "Deslogado."
    "msg.list_fail"             = "Falha ao recuperar lista de licencas. Sessao pode ter expirado."
    "msg.invalid_license"       = "Nao e um ID de Licenca valido."
    "msg.license_detail_fail"   = "Nao foi possivel obter detalhes da licenca."
    "msg.invalid_domain"        = "Nome de dominio invalido."
    "msg.txt_required"          = "Verificacao TXT Necessaria:"
    "msg.txt_add"               = "Adicione este registro TXT ao DNS do seu dominio:"
    "msg.txt_type"              = "Tipo: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Valor: ZONELY-{0}"
    "msg.txt_added"             = "Voce adicionou o registro TXT?"
    "msg.verifying"             = "Verificando..."
    "msg.txt_verified"          = "TXT Verificado!"
    "msg.txt_failed"            = "Verificacao TXT falhou."
    "msg.retry_verify"          = "Tentar verificacao novamente?"
    "msg.domain_updated"        = "Dominio atualizado com sucesso."
    "msg.domain_update_fail"    = "Falha ao atualizar dominio."
    "msg.setup_starting"        = "Iniciando Auto Setup..."
    "msg.setup_finished"        = "Processo de instalacao finalizado."
    "msg.setup_start_fail"      = "Nao foi possivel iniciar o auto setup."
    "msg.sql_ok"                = "Dump SQL baixado para: {0}"
    "msg.sql_empty"             = "Dump SQL falhou (arquivo vazio)."
    "msg.sql_error"             = "Erro no Dump SQL: {0}"
    "msg.authme_build_fail"     = "Nao foi possivel construir config AuthMe."
    "msg.authme_saved"          = "Config AuthMe salva em: {0}"
    "msg.authme_info_fail"      = "Nao foi possivel obter info da licenca para config."
    "msg.db_info"               = "Informacoes do Banco de Dados:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Porta: {0}"
    "msg.db_user_line"          = "Usuario: {0}"
    "msg.db_pass_line"          = "Senha: {0}"
    "msg.db_name_line"          = "Nome DB: {0}"
    "msg.dns_required"          = "Verificacao DNS Necessaria"
    "msg.dns_add"               = "Adicione estes registros ao seu painel DNS:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Ativado)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Ativado)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Voce adicionou os registros DNS?"
    "msg.dns_failed"            = "Verificacao falhou. Verifique seu DNS."
    "msg.retry"                 = "Tentar novamente?"
    "msg.creating_license"      = "Criando licenca..."
    "msg.license_purchased"     = "Licenca comprada com sucesso!"
    "msg.starting_initial"      = "Iniciando configuracao inicial..."
    "msg.license_setup_started" = "Setup da licenca iniciado. Estara pronto em ~30 minutos."
    "msg.purchase_failed"       = "Compra falhou."
    "msg.discord_token_missing" = "Token rememberMe nao encontrado. Faca login primeiro."
    "msg.discord_opening"       = "Abrindo verificacao Discord: {0}"
    "msg.browser_open_fail"     = "Nao foi possivel abrir o navegador."
    "msg.discord_opened"        = "Verificacao Discord aberta. Pressione Enter quando terminar..."
    "msg.fatal_error"           = "Erro Fatal: {0}"
    "msg.no_licenses"           = "Nenhuma licenca encontrada."
    "msg.licenses_header"       = "-- Suas Licencas --"
    "msg.license_line"          = "| Dominio: {0} | Expiracao: {1}"
    "msg.setup_wait"            = "Setup iniciado. Aguardando progresso..."
    "msg.setup_timeout"         = "Instalacao pode estar demorando demais."
    "label.setup"               = "Setup"
    "menu.welcome"              = "Bem-vindo! Faca login ou registre-se."
    "menu.login"                = "Entrar"
    "menu.register"             = "Registrar"
    "menu.exit"                 = "Sair"
    "menu.main"                 = "Menu Principal"
    "menu.list"                 = "Listar Licencas"
    "menu.details"              = "Ver Detalhes da Licenca"
    "menu.update_domain"        = "Atualizar Dominio"
    "menu.autosetup"            = "Iniciar Auto Setup"
    "menu.sqldump"              = "Baixar Dump SQL"
    "menu.authme"               = "Gerar Config AuthMe"
    "menu.dbinfo"               = "Ver Credenciais DB"
    "menu.buy"                  = "Comprar Nova Licenca"
    "menu.discord"              = "Verificar Cargo Discord"
    "menu.logout"               = "Sair"
}

$script:Translations["ro_RO"] = @{
    "ui.select_language"        = "Selectati Limba"
    "ui.use_arrows"             = "Folositi sagetile SUS/JOS pentru navigare, ENTER pentru selectare."
    "ui.loading"                = "Se incarca, va rugam asteptati..."
    "header.tagline1"           = "Infrastructura puternica, sigura si scalabila pentru proiecte moderne."
    "header.tagline2"           = "Jocuri, licentiere, gazduire, integrari si management intr-un singur loc."
    "header.website"            = "Website"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (da/nu): "
    "prompt.press_enter"        = "Apasati Enter pentru a continua..."
    "prompt.press_enter_done"   = "Apasati Enter cand ati terminat..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Parola"
    "prompt.first_name"         = "Prenume"
    "prompt.last_name"          = "Nume"
    "prompt.confirm_password"   = "Confirmati Parola"
    "prompt.license_id"         = "ID Licenta"
    "prompt.license_id_default" = "ID Licenta"
    "prompt.new_domain"         = "Introduceti Nume Domeniu Nou"
    "prompt.buy_domain"         = "Introduceti Domeniu pentru Cumparare Licenta"
    "msg.answer_yes_no"         = "Va rugam raspundeti cu da sau nu."
    "msg.base_url_missing"      = "Base URL nu este setat. Configurati BaseUrl/BaseUrlEnc sau variabile de mediu."
    "msg.load_cookies_fail"     = "Nu s-au putut incarca cookie-urile: {0}"
    "msg.save_cookies_fail"     = "Nu s-au putut salva cookie-urile: {0}"
    "msg.read_license_fail"     = "Nu s-au putut citi datele licentei: {0}"
    "msg.save_license_ok"       = "Info licenta salvat local."
    "msg.save_license_fail"     = "Nu s-au putut salva datele licentei: {0}"
    "msg.current_license"       = "Info Licenta Curenta:"
    "msg.license_id"            = "- ID Licenta: {0}"
    "msg.domain"                = "- Domeniu: {0}"
    "msg.expiry"                = "- Data Expirare: {0}"
    "msg.db_host"               = "- Gazda DB: {0}"
    "msg.db_port"               = "- Port DB: {0}"
    "msg.db_user"               = "- Utilizator DB: {0}"
    "msg.db_pass"               = "- Parola DB: {0}"
    "msg.db_name"               = "- Nume DB: {0}"
    "msg.cloudflare"            = "Cloudflare detectat (pagina CSRF)."
    "prompt.cookie_header"      = "Introduceti Header Cookie Browser (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Nu s-a putut obtine token CSRF. Eroare: {0}"
    "msg.login_success"         = "Autentificare reusita."
    "msg.login_failed"          = "Autentificare esuata."
    "msg.login_2fa"             = "Autentificare in doi pasi necesara. Completati login-ul pe site."
    "msg.unexpected_response"   = "Raspuns neasteptat de la server."
    "msg.register_success"      = "Inregistrare reusita."
    "msg.register_failed"       = "Inregistrare esuata."
    "msg.register_mismatch"     = "Parolele nu se potrivesc."
    "msg.register_auto"         = "Inregistrare reusita! Autentificat automat."
    "msg.logged_out"            = "Deconectat."
    "msg.list_fail"             = "Nu s-a putut prelua lista de licente. Sesiunea poate fi expirata."
    "msg.invalid_license"       = "Acesta nu este un ID de licenta valid."
    "msg.license_detail_fail"   = "Nu s-au putut prelua detaliile licentei."
    "msg.invalid_domain"        = "Nume domeniu invalid."
    "msg.txt_required"          = "Verificare TXT Necesara:"
    "msg.txt_add"               = "Adaugati aceasta inregistrare TXT in DNS-ul domeniului:"
    "msg.txt_type"              = "Tip: TXT"
    "msg.txt_host"              = "Gazda: @"
    "msg.txt_value"             = "Valoare: ZONELY-{0}"
    "msg.txt_added"             = "Ati adaugat inregistrarea TXT?"
    "msg.verifying"             = "Se verifica..."
    "msg.txt_verified"          = "TXT Verificat!"
    "msg.txt_failed"            = "Verificare TXT esuata."
    "msg.retry_verify"          = "Reincercati verificarea?"
    "msg.domain_updated"        = "Domeniu actualizat cu succes."
    "msg.domain_update_fail"    = "Nu s-a putut actualiza domeniul."
    "msg.setup_starting"        = "Pornire Auto Setup..."
    "msg.setup_finished"        = "Proces de instalare terminat."
    "msg.setup_start_fail"      = "Nu s-a putut porni auto setup."
    "msg.sql_ok"                = "Dump SQL descarcat in: {0}"
    "msg.sql_empty"             = "Dump SQL esuat (fisier gol)."
    "msg.sql_error"             = "Eroare Dump SQL: {0}"
    "msg.authme_build_fail"     = "Nu s-a putut construi config AuthMe."
    "msg.authme_saved"          = "Config AuthMe salvat in: {0}"
    "msg.authme_info_fail"      = "Nu s-a putut prelua info licenta pentru config."
    "msg.db_info"               = "Informatii Baza de Date:"
    "msg.db_host_line"          = "Gazda: {0}"
    "msg.db_port_line"          = "Port: {0}"
    "msg.db_user_line"          = "Utilizator: {0}"
    "msg.db_pass_line"          = "Parola: {0}"
    "msg.db_name_line"          = "Nume DB: {0}"
    "msg.dns_required"          = "Verificare DNS Necesara"
    "msg.dns_add"               = "Adaugati aceste inregistrari in panoul DNS:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Activat)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Activat)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Ati adaugat inregistrarile DNS?"
    "msg.dns_failed"            = "Verificare esuata. Verificati DNS-ul."
    "msg.retry"                 = "Reincercati?"
    "msg.creating_license"      = "Creare licenta..."
    "msg.license_purchased"     = "Licenta cumparata cu succes!"
    "msg.starting_initial"      = "Pornire setare initiala..."
    "msg.license_setup_started" = "Setare licenta pornita. Va fi gata in ~30 minute."
    "msg.purchase_failed"       = "Cumparare esuata."
    "msg.discord_token_missing" = "Token rememberMe nu a fost gasit. Conectati-va mai intai."
    "msg.discord_opening"       = "Deschidere verificare Discord: {0}"
    "msg.browser_open_fail"     = "Nu s-a putut deschide browserul."
    "msg.discord_opened"        = "Verificare Discord deschisa. Apasati Enter cand ati terminat..."
    "msg.fatal_error"           = "Eroare Fatala: {0}"
    "msg.no_licenses"           = "Nicio licenta gasita."
    "msg.licenses_header"       = "-- Licentele Tale --"
    "msg.license_line"          = "| Domeniu: {0} | Expirare: {1}"
    "msg.setup_wait"            = "Setare pornita. Asteptare progres..."
    "msg.setup_timeout"         = "Instalarea poate dura prea mult."
    "label.setup"               = "Setare"
    "menu.welcome"              = "Bun venit! Conectati-va sau inregistrati-va."
    "menu.login"                = "Autentificare"
    "menu.register"             = "Inregistrare"
    "menu.exit"                 = "Iesire"
    "menu.main"                 = "Meniu Principal"
    "menu.list"                 = "Lista Licente"
    "menu.details"              = "Detalii Licenta"
    "menu.update_domain"        = "Actualizare Domeniu"
    "menu.autosetup"            = "Start Auto Setup"
    "menu.sqldump"              = "Descarcare Dump SQL"
    "menu.authme"               = "Generare Config AuthMe"
    "menu.dbinfo"               = "Informatii DB"
    "menu.buy"                  = "Cumparare Licenta Noua"
    "menu.discord"              = "Verificare Rol Discord"
    "menu.logout"               = "Deconectare"
}

$script:Translations["ru_RU"] = @{
    "ui.select_language"        = "Выберите Язык"
    "ui.use_arrows"             = "Используйте стрелки ВВЕРХ/ВНИЗ для навигации, ENTER для выбора."
    "ui.loading"                = "Загрузка, пожалуйста подождите..."
    "header.tagline1"           = "Мощная, безопасная и масштабируемая инфраструктура для современных проектов."
    "header.tagline2"           = "Игры, лицензирование, хостинг, интеграции и управление в одном месте."
    "header.website"            = "Вебсайт"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (да/нет): "
    "prompt.press_enter"        = "Нажмите Enter для продолжения..."
    "prompt.press_enter_done"   = "Нажмите Enter когда закончите..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Пароль"
    "prompt.first_name"         = "Имя"
    "prompt.last_name"          = "Фамилия"
    "prompt.confirm_password"   = "Подтвердите Пароль"
    "prompt.license_id"         = "ID Лицензии"
    "prompt.license_id_default" = "ID Лицензии"
    "prompt.new_domain"         = "Введите Новое Доменное Имя"
    "prompt.buy_domain"         = "Введите Домен для Покупки Лицензии"
    "msg.answer_yes_no"         = "Пожалуйста, ответьте да или нет."
    "msg.base_url_missing"      = "Base URL не установлен. Настройте BaseUrl/BaseUrlEnc или переменные окружения."
    "msg.load_cookies_fail"     = "Не удалось загрузить куки: {0}"
    "msg.save_cookies_fail"     = "Не удалось сохранить куки: {0}"
    "msg.read_license_fail"     = "Не удалось прочитать данные лицензии: {0}"
    "msg.save_license_ok"       = "Информация о лицензии сохранена локально."
    "msg.save_license_fail"     = "Не удалось сохранить данные лицензии: {0}"
    "msg.current_license"       = "Текущая Информация о Лицензии:"
    "msg.license_id"            = "- ID Лицензии: {0}"
    "msg.domain"                = "- Домен: {0}"
    "msg.expiry"                = "- Дата Истечения: {0}"
    "msg.db_host"               = "- Хост БД: {0}"
    "msg.db_port"               = "- Порт БД: {0}"
    "msg.db_user"               = "- Пользователь БД: {0}"
    "msg.db_pass"               = "- Пароль БД: {0}"
    "msg.db_name"               = "- Имя БД: {0}"
    "msg.cloudflare"            = "Обнаружен Cloudflare (CSRF страница)."
    "prompt.cookie_header"      = "Введите Заголовок Cookie Браузера (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Не удалось получить CSRF токен. Ошибка: {0}"
    "msg.login_success"         = "Вход выполнен успешно."
    "msg.login_failed"          = "Ошибка входа."
    "msg.login_2fa"             = "Требуется двухфакторная аутентификация. Пожалуйста, завершите вход на сайте."
    "msg.unexpected_response"   = "Неожиданный ответ от сервера."
    "msg.register_success"      = "Регистрация успешна."
    "msg.register_failed"       = "Ошибка регистрации."
    "msg.register_mismatch"     = "Пароли не совпадают."
    "msg.register_auto"         = "Регистрация успешна! Автоматический вход выполнен."
    "msg.logged_out"            = "Вышли из системы."
    "msg.list_fail"             = "Не удалось получить список лицензий. Сессия могла истечь."
    "msg.invalid_license"       = "Это не действительный ID Лицензии."
    "msg.license_detail_fail"   = "Не удалось получить детали лицензии."
    "msg.invalid_domain"        = "Неверное доменное имя."
    "msg.txt_required"          = "Требуется проверка TXT:"
    "msg.txt_add"               = "Добавьте эту запись TXT в DNS вашего домена:"
    "msg.txt_type"              = "Тип: TXT"
    "msg.txt_host"              = "Хост: @"
    "msg.txt_value"             = "Значение: ZONELY-{0}"
    "msg.txt_added"             = "Вы добавили запись TXT?"
    "msg.verifying"             = "Проверка..."
    "msg.txt_verified"          = "TXT Проверен!"
    "msg.txt_failed"            = "Проверка TXT не удалась."
    "msg.retry_verify"          = "Повторить проверку?"
    "msg.domain_updated"        = "Домен успешно обновлен."
    "msg.domain_update_fail"    = "Не удалось обновить домен."
    "msg.setup_starting"        = "Запуск Автонастройки..."
    "msg.setup_finished"        = "Процесс установки завершен."
    "msg.setup_start_fail"      = "Не удалось запустить автонастройку."
    "msg.sql_ok"                = "SQL дамп загружен в: {0}"
    "msg.sql_empty"             = "SQL дамп не удался (пустой файл)."
    "msg.sql_error"             = "Ошибка SQL дампа: {0}"
    "msg.authme_build_fail"     = "Не удалось создать конфиг AuthMe."
    "msg.authme_saved"          = "Конфиг AuthMe сохранен в: {0}"
    "msg.authme_info_fail"      = "Не удалось получить информацию о лицензии для конфига."
    "msg.db_info"               = "Информация о Базе Данных:"
    "msg.db_host_line"          = "Хост: {0}"
    "msg.db_port_line"          = "Порт: {0}"
    "msg.db_user_line"          = "Пользователь: {0}"
    "msg.db_pass_line"          = "Пароль: {0}"
    "msg.db_name_line"          = "Имя БД: {0}"
    "msg.dns_required"          = "Требуется проверка DNS"
    "msg.dns_add"               = "Пожалуйста, добавьте эти записи в вашу панель DNS:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Прокси Включен)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Прокси Включен)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Вы добавили записи DNS?"
    "msg.dns_failed"            = "Проверка не удалась. Проверьте ваш DNS."
    "msg.retry"                 = "Повторить?"
    "msg.creating_license"      = "Создание лицензии..."
    "msg.license_purchased"     = "Лицензия успешно куплена!"
    "msg.starting_initial"      = "Запуск начальной настройки..."
    "msg.license_setup_started" = "Настройка лицензии началась. Будет готова через ~30 минут."
    "msg.purchase_failed"       = "Покупка не удалась."
    "msg.discord_token_missing" = "Токен rememberMe не найден. Пожалуйста, войдите сначала."
    "msg.discord_opening"       = "Открытие проверки Discord: {0}"
    "msg.browser_open_fail"     = "Не удалось открыть браузер."
    "msg.discord_opened"        = "Проверка Discord открыта. Нажмите Enter когда закончите..."
    "msg.fatal_error"           = "Критическая Ошибка: {0}"
    "msg.no_licenses"           = "Лицензии не найдены."
    "msg.licenses_header"       = "-- Ваши Лицензии --"
    "msg.license_line"          = "| Домен: {0} | Истекает: {1}"
    "msg.setup_wait"            = "Настройка началась. Ожидание прогресса..."
    "msg.setup_timeout"         = "Установка может занять слишком много времени."
    "label.setup"               = "Настройка"
    "menu.welcome"              = "Добро пожаловать! Пожалуйста, войдите или зарегистрируйтесь."
    "menu.login"                = "Вход"
    "menu.register"             = "Регистрация"
    "menu.exit"                 = "Выход"
    "menu.main"                 = "Главное Меню"
    "menu.list"                 = "Список Лицензий"
    "menu.details"              = "Детали Лицензии"
    "menu.update_domain"        = "Обновить Домен"
    "menu.autosetup"            = "Запуск Автонастройки"
    "menu.sqldump"              = "Скачать SQL Дамп"
    "menu.authme"               = "Создать Конфиг AuthMe"
    "menu.dbinfo"               = "Смотреть Данные БД"
    "menu.buy"                  = "Купить Новую Лицензию"
    "menu.discord"              = "Проверить Роль Discord"
    "menu.logout"               = "Выйти"
}

$script:Translations["sv_SE"] = @{
    "ui.select_language"        = "Välj Språk"
    "ui.use_arrows"             = "Använd UPP/NER pilarna för att navigera, ENTER för att välja."
    "ui.loading"                = "Laddar, vänligen vänta..."
    "header.tagline1"           = "Kraftfull, säker och skalbar infrastruktur för moderna projekt."
    "header.tagline2"           = "Spel, licensiering, hosting, integrationer och hantering på ett ställe."
    "header.website"            = "Hemsida"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (ja/nej): "
    "prompt.press_enter"        = "Tryck Enter för att fortsätta..."
    "prompt.press_enter_done"   = "Tryck Enter när du är klar..."
    "prompt.email"              = "E-post"
    "prompt.password"           = "Lösenord"
    "prompt.first_name"         = "Förnamn"
    "prompt.last_name"          = "Efternamn"
    "prompt.confirm_password"   = "Bekräfta Lösenord"
    "prompt.license_id"         = "Licens-ID"
    "prompt.license_id_default" = "Licens-ID"
    "prompt.new_domain"         = "Ange Nytt Domännamn"
    "prompt.buy_domain"         = "Ange Domän för att Köpa Licens"
    "msg.answer_yes_no"         = "Vänligen svara ja eller nej."
    "msg.base_url_missing"      = "Base URL ej inställd. Konfigurera BaseUrl/BaseUrlEnc eller miljövariabler."
    "msg.load_cookies_fail"     = "Misslyckades att ladda cookies: {0}"
    "msg.save_cookies_fail"     = "Misslyckades att spara cookies: {0}"
    "msg.read_license_fail"     = "Misslyckades att läsa licensdata: {0}"
    "msg.save_license_ok"       = "Licensinfo sparad lokalt."
    "msg.save_license_fail"     = "Misslyckades att spara licensdata: {0}"
    "msg.current_license"       = "Nuvarande Licensinfo:"
    "msg.license_id"            = "- Licens-ID: {0}"
    "msg.domain"                = "- Domän: {0}"
    "msg.expiry"                = "- Utgångsdatum: {0}"
    "msg.db_host"               = "- DB Värd: {0}"
    "msg.db_port"               = "- DB Port: {0}"
    "msg.db_user"               = "- DB Användare: {0}"
    "msg.db_pass"               = "- DB Lösenord: {0}"
    "msg.db_name"               = "- DB Namn: {0}"
    "msg.cloudflare"            = "Cloudflare upptäckt (CSRF sida)."
    "prompt.cookie_header"      = "Ange Webbläsarens Cookie Header (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Misslyckades att hämta CSRF-token. Fel: {0}"
    "msg.login_success"         = "Inloggning lyckades."
    "msg.login_failed"          = "Inloggning misslyckades."
    "msg.login_2fa"             = "Tvåfaktorsautentisering krävs. Vänligen slutför inloggningen på webbplatsen."
    "msg.unexpected_response"   = "Oväntat svar från servern."
    "msg.register_success"      = "Registrering lyckades."
    "msg.register_failed"       = "Registrering misslyckades."
    "msg.register_mismatch"     = "Lösenorden matchar inte."
    "msg.register_auto"         = "Registrering lyckades! Inloggad automatiskt."
    "msg.logged_out"            = "Utloggad."
    "msg.list_fail"             = "Misslyckades att hämta licenslista. Sessionen kan ha gått ut."
    "msg.invalid_license"       = "Det är inte ett giltigt Licens-ID."
    "msg.license_detail_fail"   = "Kunde inte hämta licensdetaljer."
    "msg.invalid_domain"        = "Ogiltigt domännamn."
    "msg.txt_required"          = "TXT Verifiering Krävs:"
    "msg.txt_add"               = "Lägg till denna TXT-post till din domäns DNS:"
    "msg.txt_type"              = "Typ: TXT"
    "msg.txt_host"              = "Värd: @"
    "msg.txt_value"             = "Värde: ZONELY-{0}"
    "msg.txt_added"             = "Har du lagt till TXT-posten?"
    "msg.verifying"             = "Verifierar..."
    "msg.txt_verified"          = "TXT Verifierad!"
    "msg.txt_failed"            = "TXT verifiering misslyckades."
    "msg.retry_verify"          = "Försöka verifiering igen?"
    "msg.domain_updated"        = "Domän uppdaterad."
    "msg.domain_update_fail"    = "Misslyckades att uppdatera domän."
    "msg.setup_starting"        = "Startar Auto Setup..."
    "msg.setup_finished"        = "Installationsprocessen klar."
    "msg.setup_start_fail"      = "Kunde inte starta auto setup."
    "msg.sql_ok"                = "SQL dump nedladdad till: {0}"
    "msg.sql_empty"             = "SQL dump misslyckades (tom fil)."
    "msg.sql_error"             = "SQL dump fel: {0}"
    "msg.authme_build_fail"     = "Kunde inte bygga AuthMe konfig."
    "msg.authme_saved"          = "AuthMe konfig sparad till: {0}"
    "msg.authme_info_fail"      = "Kunde inte hämta licensinfo för konfig."
    "msg.db_info"               = "Databasinformation:"
    "msg.db_host_line"          = "Värd: {0}"
    "msg.db_port_line"          = "Port: {0}"
    "msg.db_user_line"          = "Användare: {0}"
    "msg.db_pass_line"          = "Lösenord: {0}"
    "msg.db_name_line"          = "DB Namn: {0}"
    "msg.dns_required"          = "DNS Verifiering Krävs"
    "msg.dns_add"               = "Vänligen lägg till dessa poster i din DNS-panel:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Aktiverad)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Aktiverad)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Har du lagt till DNS-posterna?"
    "msg.dns_failed"            = "Verifiering misslyckades. Kontrollera din DNS."
    "msg.retry"                 = "Försöka igen?"
    "msg.creating_license"      = "Skapar licens..."
    "msg.license_purchased"     = "Licens köpt!"
    "msg.starting_initial"      = "Startar initial setup..."
    "msg.license_setup_started" = "Licens setup startad. Det kommer vara klart om ~30 minuter."
    "msg.purchase_failed"       = "Köp misslyckades."
    "msg.discord_token_missing" = "rememberMe token hittades inte. Vänligen logga in först."
    "msg.discord_opening"       = "Öppnar Discord verifiering: {0}"
    "msg.browser_open_fail"     = "Kunde inte öppna webbläsare."
    "msg.discord_opened"        = "Discord verifiering öppnad. Tryck Enter när du är klar..."
    "msg.fatal_error"           = "Allvarligt Fel: {0}"
    "msg.no_licenses"           = "Inga licenser hittades."
    "msg.licenses_header"       = "-- Dina Licenser --"
    "msg.license_line"          = "| Domän: {0} | Utgår: {1}"
    "msg.setup_wait"            = "Setup startad. Väntar på framsteg..."
    "msg.setup_timeout"         = "Installationen kan ta för lång tid."
    "label.setup"               = "Setup"
    "menu.welcome"              = "Välkommen! Vänligen logga in eller registrera dig."
    "menu.login"                = "Logga In"
    "menu.register"             = "Registrera"
    "menu.exit"                 = "Avsluta"
    "menu.main"                 = "Huvudmeny"
    "menu.list"                 = "Lista Licenser"
    "menu.details"              = "Visa Licensdetaljer"
    "menu.update_domain"        = "Uppdatera Domän"
    "menu.autosetup"            = "Starta Auto Setup"
    "menu.sqldump"              = "Ladda Ner SQL Dump"
    "menu.authme"               = "Generera AuthMe Konfig"
    "menu.dbinfo"               = "Visa DB Uppgifter"
    "menu.buy"                  = "Köp Ny Licens"
    "menu.discord"              = "Verifiera Discord Roll"
    "menu.logout"               = "Logga Ut"
}

$script:Translations["vi_VN"] = @{
    "ui.select_language"        = "Chon Ngon Ngu"
    "ui.use_arrows"             = "Dung mui ten LEN/XUONG de dieu huong, ENTER de chon."
    "ui.loading"                = "Dang tai, vui long cho..."
    "header.tagline1"           = "Co so ha tang manh me, an toan va co the mo rong cho cac du an hien dai."
    "header.tagline2"           = "Game, cap phep, luu tru, tich hop va quan ly o mot noi."
    "header.website"            = "Trang Web"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (co/khong): "
    "prompt.press_enter"        = "Nhan Enter de tiep tuc..."
    "prompt.press_enter_done"   = "Nhan Enter khi hoan thanh..."
    "prompt.email"              = "Email"
    "prompt.password"           = "Mat khau"
    "prompt.first_name"         = "Ten"
    "prompt.last_name"          = "Ho"
    "prompt.confirm_password"   = "Xac nhan Mat khau"
    "prompt.license_id"         = "ID Giay phep"
    "prompt.license_id_default" = "ID Giay phep"
    "prompt.new_domain"         = "Nhap Ten Mien Moi"
    "prompt.buy_domain"         = "Nhap Ten Mien de Mua Giay phep"
    "msg.answer_yes_no"         = "Vui long tra loi co hoac khong."
    "msg.base_url_missing"      = "Base URL chua duoc thiet lap. Cau hinh BaseUrl/BaseUrlEnc hoac bien moi truong."
    "msg.load_cookies_fail"     = "Khong the tai cookies: {0}"
    "msg.save_cookies_fail"     = "Khong the luu cookies: {0}"
    "msg.read_license_fail"     = "Khong the doc du lieu giay phep: {0}"
    "msg.save_license_ok"       = "Thong tin giay phep da duoc luu cuc bo."
    "msg.save_license_fail"     = "Khong the luu du lieu giay phep: {0}"
    "msg.current_license"       = "Thong tin Giay phep Hien tai:"
    "msg.license_id"            = "- ID Giay phep: {0}"
    "msg.domain"                = "- Ten mien: {0}"
    "msg.expiry"                = "- Ngay het han: {0}"
    "msg.db_host"               = "- Host DB: {0}"
    "msg.db_port"               = "- Cong DB: {0}"
    "msg.db_user"               = "- Nguoi dung DB: {0}"
    "msg.db_pass"               = "- Mat khau DB: {0}"
    "msg.db_name"               = "- Ten DB: {0}"
    "msg.cloudflare"            = "Cloudflare duoc phat hien (trang CSRF)."
    "prompt.cookie_header"      = "Nhap Header Cookie trinh duyet (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "Khong the lay token CSRF. Loi: {0}"
    "msg.login_success"         = "Dang nhap thanh cong."
    "msg.login_failed"          = "Dang nhap that bai."
    "msg.login_2fa"             = "Yeu cau xac thuc hai yeu to. Vui long hoan tat dang nhap tren trang web."
    "msg.unexpected_response"   = "Phan hoi khong mong doi tu may chu."
    "msg.register_success"      = "Dang ky thanh cong."
    "msg.register_failed"       = "Dang ky that bai."
    "msg.register_mismatch"     = "Mat khau khong khop."
    "msg.register_auto"         = "Dang ky thanh cong! Da dang nhap tu dong."
    "msg.logged_out"            = "Da dang xuat."
    "msg.list_fail"             = "Khong the lay danh sach giay phep. Phien co the da het han."
    "msg.invalid_license"       = "Do khong phai la ID Giay phep hop le."
    "msg.license_detail_fail"   = "Khong the lay chi tiet giay phep."
    "msg.invalid_domain"        = "Ten mien khong hop le."
    "msg.txt_required"          = "Yeu cau Xac minh TXT:"
    "msg.txt_add"               = "Them ban ghi TXT nay vao DNS ten mien cua ban:"
    "msg.txt_type"              = "Loai: TXT"
    "msg.txt_host"              = "Host: @"
    "msg.txt_value"             = "Gia tri: ZONELY-{0}"
    "msg.txt_added"             = "Ban da them ban ghi TXT chua?"
    "msg.verifying"             = "Dang xac minh..."
    "msg.txt_verified"          = "TXT Da xac minh!"
    "msg.txt_failed"            = "Xac minh TXT that bai."
    "msg.retry_verify"          = "Thu xac minh lai?"
    "msg.domain_updated"        = "Cap nhat ten mien thanh cong."
    "msg.domain_update_fail"    = "Khong the cap nhat ten mien."
    "msg.setup_starting"        = "Dang khoi dong Auto Setup..."
    "msg.setup_finished"        = "Qua trinh cai dat hoan tat."
    "msg.setup_start_fail"      = "Khong the khoi dong auto setup."
    "msg.sql_ok"                = "SQL dump da tai xuong: {0}"
    "msg.sql_empty"             = "SQL dump that bai (tap tin trong)."
    "msg.sql_error"             = "Loi SQL dump: {0}"
    "msg.authme_build_fail"     = "Khong the xay dung cau hinh AuthMe."
    "msg.authme_saved"          = "Cau hinh AuthMe da luu tai: {0}"
    "msg.authme_info_fail"      = "Khong the lay thong tin giay phep cho cau hinh."
    "msg.db_info"               = "Thong tin Co so Du lieu:"
    "msg.db_host_line"          = "Host: {0}"
    "msg.db_port_line"          = "Cong: {0}"
    "msg.db_user_line"          = "Nguoi dung: {0}"
    "msg.db_pass_line"          = "Mat khau: {0}"
    "msg.db_name_line"          = "Ten DB: {0}"
    "msg.dns_required"          = "Yeu cau Xac minh DNS"
    "msg.dns_add"               = "Vui long them cac ban ghi nay vao bang dieu khien DNS cua ban:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Da bat)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Da bat)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "Ban da them cac ban ghi DNS chua?"
    "msg.dns_failed"            = "Xac minh that bai. Kiem tra DNS cua ban."
    "msg.retry"                 = "Thu lai?"
    "msg.creating_license"      = "Dang tao giay phep..."
    "msg.license_purchased"     = "Mua giay phep thanh cong!"
    "msg.starting_initial"      = "Dang khoi dong thiet lap ban dau..."
    "msg.license_setup_started" = "Thiet lap giay phep da bat dau. Se san sang trong ~30 phut."
    "msg.purchase_failed"       = "Mua that bai."
    "msg.discord_token_missing" = "Khong tim thay token rememberMe. Vui long dang nhap truoc."
    "msg.discord_opening"       = "Dang mo xac minh Discord: {0}"
    "msg.browser_open_fail"     = "Khong the mo trinh duyet."
    "msg.discord_opened"        = "Xac minh Discord da mo. Nhan Enter khi hoan thanh..."
    "msg.fatal_error"           = "Loi Nghiem trong: {0}"
    "msg.no_licenses"           = "Khong tim thay giay phep nao."
    "msg.licenses_header"       = "-- Giay phep cua ban --"
    "msg.license_line"          = "| Ten mien: {0} | Het han: {1}"
    "msg.setup_wait"            = "Thiet lap da bat dau. Dang cho tien do..."
    "msg.setup_timeout"         = "Cai dat co the dang mat qua nhieu thoi gian."
    "label.setup"               = "Cai dat"
    "menu.welcome"              = "Chao mung! Vui long dang nhap hoac dang ky."
    "menu.login"                = "Dang nhap"
    "menu.register"             = "Dang ky"
    "menu.exit"                 = "Thoat"
    "menu.main"                 = "Menu Chinh"
    "menu.list"                 = "Danh sach Giay phep"
    "menu.details"              = "Xem Chi tiet Giay phep"
    "menu.update_domain"        = "Cap nhat Ten mien"
    "menu.autosetup"            = "Bat dau Auto Setup"
    "menu.sqldump"              = "Tai xuong SQL Dump"
    "menu.authme"               = "Tao Cau hinh AuthMe"
    "menu.dbinfo"               = "Xem Thong tin DB"
    "menu.buy"                  = "Mua Giay phep Moi"
    "menu.discord"              = "Xac minh Vai tro Discord"
    "menu.logout"               = "Dang xuat"
}

$script:Translations["zh_CN"] = @{
    "ui.select_language"        = "选择语言"
    "ui.use_arrows"             = "使用 上/下 箭头导航，回车键选择。"
    "ui.loading"                = "加载中，请稍候..."
    "header.tagline1"           = "为现代项目打造的强大、安全且可扩展的基础设施。"
    "header.tagline2"           = "游戏、授权、托管、集成和管理，一站式服务。"
    "header.website"            = "网站"
    "header.discord"            = "Discord"
    "prompt.yes_no"             = "{0} (是/否): "
    "prompt.press_enter"        = "按回车键继续..."
    "prompt.press_enter_done"   = "完成后按回车键..."
    "prompt.email"              = "邮箱"
    "prompt.password"           = "密码"
    "prompt.first_name"         = "名"
    "prompt.last_name"          = "姓"
    "prompt.confirm_password"   = "确认密码"
    "prompt.license_id"         = "许可证ID"
    "prompt.license_id_default" = "许可证ID"
    "prompt.new_domain"         = "输入新域名"
    "prompt.buy_domain"         = "输入域名购买许可证"
    "msg.answer_yes_no"         = "请回答是或否。"
    "msg.base_url_missing"      = "未设置 Base URL。配置 BaseUrl/BaseUrlEnc 或环境变量。"
    "msg.load_cookies_fail"     = "加载 Cookies 失败: {0}"
    "msg.save_cookies_fail"     = "保存 Cookies 失败: {0}"
    "msg.read_license_fail"     = "读取许可证数据失败: {0}"
    "msg.save_license_ok"       = "许可证信息已保存到本地。"
    "msg.save_license_fail"     = "保存许可证数据失败: {0}"
    "msg.current_license"       = "当前许可证信息:"
    "msg.license_id"            = "- 许可证ID: {0}"
    "msg.domain"                = "- 域名: {0}"
    "msg.expiry"                = "- 过期日期: {0}"
    "msg.db_host"               = "- 数据库主机: {0}"
    "msg.db_port"               = "- 数据库端口: {0}"
    "msg.db_user"               = "- 数据库用户: {0}"
    "msg.db_pass"               = "- 数据库密码: {0}"
    "msg.db_name"               = "- 数据库名: {0}"
    "msg.cloudflare"            = "检测到 Cloudflare (CSRF 页面)。"
    "prompt.cookie_header"      = "请输入浏览器 Cookie Header (cf_clearance=...; __cf_bm=...)"
    "msg.csrf_failed"           = "获取 CSRF 令牌失败。错误: {0}"
    "msg.login_success"         = "登录成功。"
    "msg.login_failed"          = "登录失败。"
    "msg.login_2fa"             = "需要双重认证。请在网站上完成登录。"
    "msg.unexpected_response"   = "服务器返回意外响应。"
    "msg.register_success"      = "注册成功。"
    "msg.register_failed"       = "注册失败。"
    "msg.register_mismatch"     = "密码不匹配。"
    "msg.register_auto"         = "注册成功！已自动登录。"
    "msg.logged_out"            = "已登出。"
    "msg.list_fail"             = "获取许可证列表失败。会话可能已过期。"
    "msg.invalid_license"       = "无效的许可证ID。"
    "msg.license_detail_fail"   = "无法获取许可证详情。"
    "msg.invalid_domain"        = "无效的域名。"
    "msg.txt_required"          = "需要 TXT 验证:"
    "msg.txt_add"               = "将此 TXT 记录添加到您的域名 DNS:"
    "msg.txt_type"              = "类型: TXT"
    "msg.txt_host"              = "主机: @"
    "msg.txt_value"             = "值: ZONELY-{0}"
    "msg.txt_added"             = "您添加了 TXT 记录吗？"
    "msg.verifying"             = "验证中..."
    "msg.txt_verified"          = "TXT 验证通过！"
    "msg.txt_failed"            = "TXT 验证失败。"
    "msg.retry_verify"          = "重试验证？"
    "msg.domain_updated"        = "域名更新成功。"
    "msg.domain_update_fail"    = "更新域名失败。"
    "msg.setup_starting"        = "正在启动自动安装..."
    "msg.setup_finished"        = "安装过程完成。"
    "msg.setup_start_fail"      = "无法启动自动安装。"
    "msg.sql_ok"                = "SQL 转储已下载到: {0}"
    "msg.sql_empty"             = "SQL 转储失败 (空文件)。"
    "msg.sql_error"             = "SQL 转储错误: {0}"
    "msg.authme_build_fail"     = "无法构建 AuthMe 配置。"
    "msg.authme_saved"          = "AuthMe 配置保存到: {0}"
    "msg.authme_info_fail"      = "无法获取配置的许可证信息。"
    "msg.db_info"               = "数据库信息:"
    "msg.db_host_line"          = "主机: {0}"
    "msg.db_port_line"          = "端口: {0}"
    "msg.db_user_line"          = "用户: {0}"
    "msg.db_pass_line"          = "密码: {0}"
    "msg.db_name_line"          = "数据库名: {0}"
    "msg.dns_required"          = "需要 DNS 验证"
    "msg.dns_add"               = "请将这些记录添加到您的 DNS 面板:"
    "msg.cname_root"            = "CNAME  {0}       ->  premium.zonely.gen.tr (代理开启)"
    "msg.cname_www"             = "CNAME  www.{0}   ->  premium.zonely.gen.tr (代理开启)"
    "msg.txt_record"            = "TXT    {0}       ->  ZONELY-{1}"
    "msg.dns_added"             = "您添加了 DNS 记录吗？"
    "msg.dns_failed"            = "验证失败。检查您的 DNS。"
    "msg.retry"                 = "重试？"
    "msg.creating_license"      = "正在创建许可证..."
    "msg.license_purchased"     = "许可证购买成功！"
    "msg.starting_initial"      = "正在启动初始设置..."
    "msg.license_setup_started" = "许可证设置已开始。约30分钟后准备就绪。"
    "msg.purchase_failed"       = "购买失败。"
    "msg.discord_token_missing" = "未找到 rememberMe 令牌。请先登录。"
    "msg.discord_opening"       = "正在打开 Discord 验证: {0}"
    "msg.browser_open_fail"     = "无法打开浏览器。"
    "msg.discord_opened"        = "Discord 验证已打开。完成后按回车键..."
    "msg.fatal_error"           = "致命错误: {0}"
    "msg.no_licenses"           = "未找到许可证。"
    "msg.licenses_header"       = "-- 您的许可证 --"
    "msg.license_line"          = "| 域名: {0} | 过期: {1}"
    "msg.setup_wait"            = "设置已开始。等待进度..."
    "msg.setup_timeout"         = "安装可能超时。"
    "label.setup"               = "安装"
    "menu.welcome"              = "欢迎！请登录或注册。"
    "menu.login"                = "登录"
    "menu.register"             = "注册"
    "menu.exit"                 = "退出"
    "menu.main"                 = "主菜单"
    "menu.list"                 = "列出许可证"
    "menu.details"              = "查看许可证详情"
    "menu.update_domain"        = "更新域名"
    "menu.autosetup"            = "启动自动安装"
    "menu.sqldump"              = "下载 SQL 转储"
    "menu.authme"               = "生成 AuthMe 配置"
    "menu.dbinfo"               = "查看数据库凭据"
    "menu.buy"                  = "购买新许可证"
    "menu.discord"              = "验证 Discord 角色"
    "menu.logout"               = "登出"
}

$script:ExtraLangPath = Join-Path $PSScriptRoot "translations-extra.ps1"
if (Test-Path $script:ExtraLangPath) { . $script:ExtraLangPath }

foreach ($loc in $script:Locales.Keys) {
    if (-not $script:Translations.ContainsKey($loc)) {
        $script:Translations[$loc] = @{}
        foreach ($k in $script:Translations["en_US"].Keys) {
            $script:Translations[$loc][$k] = $script:Translations["en_US"][$k]
        }
    }
}

function T([string]$Key, [string]$Fallback, [object[]]$Params) {
    $lang = $script:Lang
    $text = $null
    if ($script:Translations.ContainsKey($lang)) {
        $dict = $script:Translations[$lang]
        if ($dict.ContainsKey($Key)) { $text = $dict[$Key] }
    }
    if (-not $text -and $script:Translations.ContainsKey("en_US")) {
        $dict = $script:Translations["en_US"]
        $text = $dict[$Key]
    }
    if (-not $text) { $text = $Fallback }
    if ($Params -and $Params.Count -gt 0) { 
        try {
            return $text -f $Params 
        }
        catch {
            return $text
        }
    }
    return $text
}
function Show-Loading([string]$Text = "Loading, please wait...", [int]$Steps = 20, [int]$DelayMs = 40) {
    $width = 80
    $height = 25
    try {
        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight
    }
    catch {}
    if ($width -le 0 -or $height -le 0) {
        try {
            if ($host.Name -eq "ConsoleHost") {
                $size = $host.UI.RawUI.WindowSize
                $width = [int]$size.Width
                $height = [int]$size.Height
            }
        }
        catch {}
    }

    $barWidth = [Math]::Max(10, [Math]::Min(30, $width - 20))
    for ($i = 0; $i -le $Steps; $i++) {
        $filled = [int][Math]::Floor($barWidth * $i / $Steps)
        $empty = $barWidth - $filled
        $bar = "[" + ("#" * $filled) + ("-" * $empty) + "]"
        $percent = [int][Math]::Round(($i / $Steps) * 100)

        $line1 = $Text
        $line2 = "$bar $percent%"
        if ($line1.Length -gt $width) { $line1 = $line1.Substring(0, $width) }
        if ($line2.Length -gt $width) { $line2 = $line2.Substring(0, $width) }
        $x1 = [Math]::Max(0, [int](($width - $line1.Length) / 2))
        $x2 = [Math]::Max(0, [int](($width - $line2.Length) / 2))
        $y1 = [Math]::Max(0, [int]($height / 2) - 1)
        $y2 = [Math]::Min([Math]::Max(0, $height - 1), $y1 + 1)

        Clear-Host
        try {
            [Console]::SetCursorPosition($x1, $y1)
            [Console]::Write($line1)
            [Console]::SetCursorPosition($x2, $y2)
            [Console]::Write($line2)
        }
        catch {
            Write-Host ((" " * $x1) + $line1)
            Write-Host ((" " * $x2) + $line2)
        }
        Start-Sleep -Milliseconds $DelayMs
    }
}

function Write-ProgressBar([int]$Percent, [string]$Label = "Setup") {
    $p = [Math]::Max(0, [Math]::Min(100, $Percent))
    $barWidth = 30
    $filled = [int][Math]::Floor($barWidth * $p / 100)
    $empty = $barWidth - $filled
    $bar = "[" + ("#" * $filled) + ("-" * $empty) + "]"
    $line = "$Label $bar $p%"
    if ($line.Length -lt 60) { $line = $line.PadRight(60) }
    Write-Host ("`r" + $line) -NoNewline
}

function Decode-Secret([string]$b64) {
    try {
        $bytes = [Convert]::FromBase64String($b64)
        return [Text.Encoding]::UTF8.GetString($bytes)
    }
    catch {
        return ""
    }
}

function Get-BaseUrl() {
    if ($env:ZONELY_BASE_URL) { return $env:ZONELY_BASE_URL }
    if ($env:ZONELY_BASE_URL_B64) {
        $v = Decode-Secret $env:ZONELY_BASE_URL_B64
        if ($v) { return $v }
    }
    if (-not [string]::IsNullOrWhiteSpace($BaseUrl)) { return $BaseUrl }
    if (-not [string]::IsNullOrWhiteSpace($BaseUrlEnc)) { return (Decode-Secret $BaseUrlEnc) }
    return ""
}

function Get-HarborNote() {
    if ($env:ZONELY_WAF_TOKEN) { return $env:ZONELY_WAF_TOKEN }
    if ($env:ZONELY_WAF_TOKEN_B64) {
        $v = Decode-Secret $env:ZONELY_WAF_TOKEN_B64
        if ($v) { return $v }
    }
    if (-not [string]::IsNullOrWhiteSpace($HarborNote)) { return $HarborNote }
    if (-not [string]::IsNullOrWhiteSpace($HarborNoteEnc)) { return (Decode-Secret $HarborNoteEnc) }
    return ""
}

function Draw-Header {
    Clear-Host
    Write-Host "                  
 ________  ________  ________   _______   ___           ___    ___ 
|\_____  \|\   __  \|\   ___  \|\  ___ \ |\  \         |\  \  /  /|
 \|___/  /\ \  \|\  \ \  \\ \  \ \   __/|\ \  \        \ \  \/  / /
     /  / /\ \  \\\  \ \  \\ \  \ \  \_|/_\ \  \        \ \    / / 
    /  /_/__\ \  \\\  \ \  \\ \  \ \  \_|\ \ \  \____    \/  /  /  
   |\________\ \_______\ \__\\ \__\ \_______\ \_______\__/  / /    
    \|_______|\|_______|\|__| \|__|\|_______|\|_______|\___/ /     
                                                      \|___|/
" -ForegroundColor Cyan
    Write-Host (T "header.tagline1" "Powerful, secure and scalable infrastructure for modern projects.") -ForegroundColor White
    Write-Host (T "header.tagline2" "Game, licensing, hosting, integrations and management in one place.") -ForegroundColor DarkGray
    Write-Host "" -ForegroundColor DarkGray
    Write-Host ((T "header.website" "Website") + ": https://zonely.gen.tr") -ForegroundColor Yellow
    Write-Host ((T "header.discord" "Discord") + ": https://discord.gg/3HGmz4H2UC") -ForegroundColor Yellow
    Write-Host "" -ForegroundColor DarkGray
    Write-Host "--------------------------------" -ForegroundColor Gray

}

function Get-RequestHeaders() {
    $h = @{
        "User-Agent"      = "ZonelyLauncher/2.0 (+https://zonely.gen.tr)"
        "Accept"          = "application/json, text/plain, */*"
        "Accept-Language" = "en-US,en;q=0.9"
        "Cache-Control"   = "no-cache"
        "Pragma"          = "no-cache"
    }
    $bk = Get-HarborNote
    if (-not [string]::IsNullOrWhiteSpace($bk)) {
        $h["X-Waf-Bypass"] = $bk
        $h["X-Waf-Token"] = $bk
    }
    return $h
}

function Join-Url([string]$Base, [string]$Path) {
    $b = $Base.TrimEnd("/")
    $p = $Path
    if (-not $p.StartsWith("/")) { $p = "/" + $p }
    return $b + $p
}

function Read-YesNo([string]$Prompt) {
    while ($true) {
        Write-Host (T "prompt.yes_no" "$Prompt (yes/no): " @($Prompt)) -NoNewline -ForegroundColor Yellow
        $ans = (Read-Host).Trim().ToLowerInvariant()
        if (@("yes", "y", "1", "evet", "e") -contains $ans) { return $true }
        if (@("no", "n", "0", "hayir", "h") -contains $ans) { return $false }
        Write-Warn (T "msg.answer_yes_no" "Please answer yes or no.")
    }
}

function Read-Input([string]$Prompt, [bool]$Secret = $false) {
    if ($Secret) {
        Write-Host "${Prompt}: " -NoNewline -ForegroundColor Yellow
        $secure = Read-Host -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        }
        finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
    else {
        Write-Host "${Prompt}: " -NoNewline -ForegroundColor Yellow
        return (Read-Host).Trim()
    }
}

function Test-CloudflareChallenge([string]$Html) {
    if ([string]::IsNullOrWhiteSpace($Html)) { return $false }
    $h = $Html.ToLowerInvariant()
    return ($h -like "*cf-chl*" -or $h -like "*challenge-platform*" -or $h -like "*cf-please-wait*")
}

function Test-WafChallenge([string]$Html) {
    if ([string]::IsNullOrWhiteSpace($Html)) { return $false }
    $h = $Html.ToLowerInvariant()
    return ($h -like "*security check in progress*" -or $h -like "*__waf_challenge*" -or $h -like "*waf_pass*")
}

function Resolve-Location([string]$Base, [string]$Location) {
    if ([string]::IsNullOrWhiteSpace($Location)) { return $null }
    try {
        $loc = [Uri]$Location
        if ($loc.IsAbsoluteUri) { return $loc.AbsoluteUri }
    }
    catch {}
    try {
        $baseUri = [Uri]$Base
        $resolved = New-Object System.Uri($baseUri, $Location)
        return $resolved.AbsoluteUri
    }
    catch {}
    return $Location
}

function Add-CookiesFromHeader([Microsoft.PowerShell.Commands.WebRequestSession]$Session, [string]$Base, [string]$CookieHeader) {
    if ([string]::IsNullOrWhiteSpace($CookieHeader)) { return }
    $baseUri = [Uri]$Base
    $parts = $CookieHeader.Split(";") | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "=" }
    foreach ($p in $parts) {
        $kv = $p.Split("=", 2)
        if ($kv.Length -lt 2) { continue }
        $name = $kv[0].Trim()
        $value = $kv[1].Trim()
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        $cookie = New-Object System.Net.Cookie($name, $value)
        $cookie.Path = "/"
        $Session.Cookies.Add($baseUri, $cookie)
    }
}

function Resolve-PathAbsolute([string]$PathOrName) {
    if ([string]::IsNullOrWhiteSpace($PathOrName)) { return $null }
    if ([System.IO.Path]::IsPathRooted($PathOrName)) { return $PathOrName }
    return (Join-Path $PSScriptRoot $PathOrName)
}

function Get-ConfigPath {
    return (Join-Path $PSScriptRoot "config.json")
}

function Get-LegacyConfigPath {
    return (Join-Path $PSScriptRoot "zonely.config.json")
}

function Load-Config {
    $path = Get-ConfigPath
    $legacy = Get-LegacyConfigPath
    if (-not (Test-Path $path) -and (Test-Path $legacy)) {
        try { Copy-Item -Path $legacy -Destination $path -Force } catch {}
    }
    if (Test-Path $path) {
        try {
            $json = Get-Content -Path $path -Raw -Encoding UTF8
            if (-not [string]::IsNullOrWhiteSpace($json)) {
                return ($json | ConvertFrom-Json)
            }
        }
        catch {}
    }
    return $null
}

function Save-Config([object]$Config) {
    $path = Get-ConfigPath
    try {
        $json = $Config | ConvertTo-Json -Depth 5
        $json | Set-Content -Path $path -Encoding UTF8
    }
    catch {}
}

function Convert-ToBool([object]$Value, [bool]$Default = $false) {
    if ($null -eq $Value) { return $Default }
    if ($Value -is [bool]) { return $Value }
    $s = ("$Value").Trim().ToLowerInvariant()
    if ($s -in @("1", "true", "yes", "y", "on")) { return $true }
    if ($s -in @("0", "false", "no", "n", "off")) { return $false }
    return $Default
}

function Get-UpdateSettings {
    $cfg = Load-Config
    $repo = $UpdateRepo
    $branch = if ($UpdateBranch) { $UpdateBranch } else { "main" }
    $baseUrl = $UpdateBaseUrl
    $enabled = $true
    $interval = 12
    $lastCheck = $null

    if ($env:ZONELY_UPDATE_REPO) { $repo = $env:ZONELY_UPDATE_REPO }
    if ($env:ZONELY_UPDATE_BRANCH) { $branch = $env:ZONELY_UPDATE_BRANCH }
    if ($env:ZONELY_UPDATE_BASEURL) { $baseUrl = $env:ZONELY_UPDATE_BASEURL }
    if ($env:ZONELY_UPDATE_ENABLED) { $enabled = Convert-ToBool $env:ZONELY_UPDATE_ENABLED $enabled }
    if ($env:ZONELY_UPDATE_INTERVAL_HOURS) {
        try { $interval = [int]$env:ZONELY_UPDATE_INTERVAL_HOURS } catch {}
    }

    if ($cfg -and ($cfg.PSObject.Properties.Name -contains "Update")) {
        $u = $cfg.Update
        if ($u -and ($u.PSObject.Properties.Name -contains "Enabled")) { $enabled = Convert-ToBool $u.Enabled $enabled }
        if ($u -and $u.Repo) { $repo = $u.Repo }
        if ($u -and $u.Branch) { $branch = $u.Branch }
        if ($u -and $u.BaseUrl) { $baseUrl = $u.BaseUrl }
        if ($u -and $u.CheckIntervalHours) {
            try { $interval = [int]$u.CheckIntervalHours } catch {}
        }
        if ($u -and $u.LastCheck) { $lastCheck = $u.LastCheck }
    }

    if (-not $baseUrl -and $repo) {
        $baseUrl = "https://raw.githubusercontent.com/$repo/$branch"
    }
    if (-not $baseUrl) { $enabled = $false }

    return [pscustomobject]@{
        Enabled = $enabled
        Repo = $repo
        Branch = $branch
        BaseUrl = $baseUrl
        CheckIntervalHours = $interval
        LastCheck = $lastCheck
    }
}

function Set-UpdateLastCheck([string]$Iso) {
    try {
        $cfg = Load-Config
        $newCfg = if ($cfg) { $cfg } else { [pscustomobject]@{} }
        if (-not ($newCfg.PSObject.Properties.Name -contains "Update")) {
            $newCfg | Add-Member -NotePropertyName Update -NotePropertyValue ([pscustomobject]@{})
        }
        $newCfg.Update.LastCheck = $Iso
        Save-Config $newCfg
    }
    catch {}
}

function Should-CheckUpdate([object]$Settings) {
    if (-not $Settings) { return $false }
    $hours = 0
    try { $hours = [int]$Settings.CheckIntervalHours } catch { $hours = 0 }
    if ($hours -le 0) { return $true }
    if (-not $Settings.LastCheck) { return $true }
    try {
        $last = [DateTime]::Parse($Settings.LastCheck)
        return ((Get-Date) - $last).TotalHours -ge $hours
    }
    catch {
        return $true
    }
}

function Ensure-Tls12 {
    try {
        $proto = [Net.ServicePointManager]::SecurityProtocol
        if (($proto -band [Net.SecurityProtocolType]::Tls12) -eq 0) {
            [Net.ServicePointManager]::SecurityProtocol = $proto -bor [Net.SecurityProtocolType]::Tls12
        }
    }
    catch {}
}

function Download-RemoteFile([string]$Url, [string]$OutPath) {
    if (-not $Url -or -not $OutPath) { return $false }
    try {
        $headers = @{ "User-Agent" = "$($script:AppName)/$($script:AppVersion)" }
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            Invoke-WebRequest -Uri $Url -OutFile $OutPath -Headers $headers -UseBasicParsing -TimeoutSec 15 | Out-Null
        }
        else {
            Invoke-WebRequest -Uri $Url -OutFile $OutPath -Headers $headers -TimeoutSec 15 | Out-Null
        }
        if (-not (Test-Path $OutPath)) { return $false }
        $len = (Get-Item $OutPath).Length
        return ($len -gt 0)
    }
    catch {
        return $false
    }
}

function Get-VersionFromText([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $m = [regex]::Match($Text, '\$script:AppVersion\s*=\s*"([^"]+)"')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    $m = [regex]::Match($Text, '\$script:AppVersion\s*=\s*''([^'']+)''')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ""
}

function Get-VersionFromFile([string]$Path) {
    if (-not (Test-Path $Path)) { return "" }
    try {
        $text = Get-Content -Path $Path -Raw -Encoding UTF8
        return (Get-VersionFromText $text)
    }
    catch {
        return ""
    }
}

function Compare-Version([string]$A, [string]$B) {
    if (-not $A -and -not $B) { return 0 }
    if (-not $A) { return -1 }
    if (-not $B) { return 1 }
    $aParts = ($A -replace "[^0-9\.]", ".").Split(".") | Where-Object { $_ -ne "" }
    $bParts = ($B -replace "[^0-9\.]", ".").Split(".") | Where-Object { $_ -ne "" }
    $len = [Math]::Max($aParts.Count, $bParts.Count)
    for ($i = 0; $i -lt $len; $i++) {
        $ai = if ($i -lt $aParts.Count) { [int]$aParts[$i] } else { 0 }
        $bi = if ($i -lt $bParts.Count) { [int]$bParts[$i] } else { 0 }
        if ($ai -gt $bi) { return 1 }
        if ($ai -lt $bi) { return -1 }
    }
    return 0
}

function Get-StartupArgs {
    $argsList = @()
    foreach ($k in $script:BoundParameters.Keys) {
        if ($k -eq "SkipUpdate") { continue }
        $v = $script:BoundParameters[$k]
        if ($v -is [System.Management.Automation.SwitchParameter]) {
            if ($v.IsPresent) { $argsList += "-$k" }
        }
        elseif ($v -is [bool]) {
            if ($v) { $argsList += "-$k" }
        }
        elseif ($null -ne $v -and "$v" -ne "") {
            $argsList += "-$k"
            $argsList += "$v"
        }
    }
    return $argsList
}

function Restart-CurrentScript {
    if (-not $PSCommandPath) { return }
    $argsList = Get-StartupArgs
    $argsList += "-SkipUpdate"
    & $PSCommandPath @argsList
    exit
}

function Invoke-AutoUpdate {
    if ($SkipUpdate) { return }
    $settings = Get-UpdateSettings
    if (-not $settings.Enabled) { return }
    if (-not (Should-CheckUpdate $settings)) { return }

    $stamp = (Get-Date).ToString("o")
    Set-UpdateLastCheck $stamp

    Write-Info (T "msg.update_checking" "Checking for updates...")
    Ensure-Tls12

    $base = $settings.BaseUrl.TrimEnd("/")
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("zonely-update-" + [guid]::NewGuid().ToString("N"))
    $ok = $false
    try {
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        $tmpPs1 = Join-Path $tempRoot "zonely.ps1"
        $remotePs1Url = "$base/zonely.ps1"
        if (-not (Download-RemoteFile -Url $remotePs1Url -OutPath $tmpPs1)) {
            Write-Warn (T "msg.update_failed" "Update failed: {0}" @("download error"))
            return
        }

        $remoteVersion = Get-VersionFromFile $tmpPs1
        $localVersion = $script:AppVersion
        $hasUpdate = $false
        $cmp = $null

        if ($remoteVersion -and $localVersion) {
            $cmp = Compare-Version $remoteVersion $localVersion
            if ($cmp -gt 0) { $hasUpdate = $true }
        }
        elseif ($remoteVersion -and -not $localVersion) {
            $hasUpdate = $true
        }

        if (-not $hasUpdate -and ($cmp -eq $null -or $cmp -eq 0)) {
            try {
                $localHash = (Get-FileHash -Path $PSCommandPath -Algorithm SHA256).Hash
                $remoteHash = (Get-FileHash -Path $tmpPs1 -Algorithm SHA256).Hash
                if ($localHash -ne $remoteHash) { $hasUpdate = $true }
            }
            catch {}
        }

        if (-not $hasUpdate) { return }

        $from = if ($localVersion) { $localVersion } else { "?" }
        $to = if ($remoteVersion) { $remoteVersion } else { "?" }
        Write-Info (T "msg.update_available" "Update available: {0} -> {1}. Downloading..." @($from, $to))

        $files = @()
        foreach ($f in $script:UpdateFiles) {
            if ($f -eq "zonely.ps1" -or (Test-Path (Join-Path $PSScriptRoot $f))) { $files += $f }
        }

        $downloads = @{}
        foreach ($f in $files) {
            $destTemp = Join-Path $tempRoot $f
            $parent = Split-Path $destTemp -Parent
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            if ($f -eq "zonely.ps1") {
                $downloads[$f] = $tmpPs1
                continue
            }
            $url = "$base/$f"
            if (-not (Download-RemoteFile -Url $url -OutPath $destTemp)) {
                throw "Failed to download $f"
            }
            $downloads[$f] = $destTemp
        }

        foreach ($f in $files) {
            $src = $downloads[$f]
            if (-not $src -or -not (Test-Path $src)) { throw "Missing download for $f" }
            $dest = Join-Path $PSScriptRoot $f
            Copy-Item -Path $src -Destination $dest -Force
        }

        $ok = $true
    }
    catch {
        Write-Warn (T "msg.update_failed" "Update failed: {0}" @($_.Exception.Message))
        return
    }
    finally {
        if (Test-Path $tempRoot) {
            try { Remove-Item -Path $tempRoot -Recurse -Force } catch {}
        }
    }

    if ($ok) {
        Write-Ok (T "msg.update_success" "Update complete. Restarting...")
        Restart-CurrentScript
    }
}

function Load-Cookies([Microsoft.PowerShell.Commands.WebRequestSession]$Session, [string]$FilePath) {
    if (-not $FilePath -or -not (Test-Path $FilePath)) { return }
    try {
        $raw = Get-Content -Path $FilePath -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { return }
        $items = $raw | ConvertFrom-Json
        if (-not $items) { return }
        foreach ($c in $items) {
            if (-not $c.name -or -not $c.value -or -not $c.domain) { continue }
            $cookie = New-Object System.Net.Cookie($c.name, $c.value)
            $cookie.Domain = $c.domain
            $cookie.Path = if ($c.path) { $c.path } else { "/" }
            if ($c.secure -eq $true) { $cookie.Secure = $true }
            if ($c.httpOnly -eq $true) { $cookie.HttpOnly = $true }
            if ($c.expires) {
                try { $cookie.Expires = [DateTime]::Parse($c.expires) } catch {}
            }
            try { $Session.Cookies.Add($cookie) } catch {}
        }
    }
    catch {
        Write-Warn (T "msg.load_cookies_fail" "Failed to load cookies: {0}" @($_.Exception.Message))
    }
}

function Save-Cookies([Microsoft.PowerShell.Commands.WebRequestSession]$Session, [string]$Base, [string]$FilePath) {
    if (-not $FilePath) { return }
    try {
        $uri = [Uri]$Base
        $jar = $Session.Cookies.GetCookies($uri)
        $list = @()
        foreach ($c in $jar) {
            $expires = if ($c.Expires -and $c.Expires -gt [DateTime]::MinValue) { $c.Expires.ToString("o") } else { $null }
            $list += [pscustomobject]@{
                name     = $c.Name
                value    = $c.Value
                domain   = $c.Domain
                path     = $c.Path
                expires  = $expires
                secure   = $c.Secure
                httpOnly = $c.HttpOnly
            }
        }
        $json = $list | ConvertTo-Json -Depth 3
        $dir = Split-Path -Parent $FilePath
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        Set-Content -Path $FilePath -Value $json -Encoding UTF8
    }
    catch {
        Write-Warn (T "msg.save_cookies_fail" "Failed to save cookies: {0}" @($_.Exception.Message))
    }
}

function Load-LicenseState([string]$FilePath) {
    if (-not $FilePath -or -not (Test-Path $FilePath)) { return $null }
    try {
        $raw = Get-Content -Path $FilePath -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        return ($raw | ConvertFrom-Json)
    }
    catch {
        Write-Warn (T "msg.read_license_fail" "Failed to read license data: {0}" @($_.Exception.Message))
        return $null
    }
}

function Save-LicenseState([string]$FilePath, [object]$State) {
    if (-not $FilePath -or -not $State) { return }
    try {
        $dir = Split-Path -Parent $FilePath
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $json = $State | ConvertTo-Json -Depth 6
        Set-Content -Path $FilePath -Value $json -Encoding UTF8
        Write-Ok (T "msg.save_license_ok" "License info saved locally.")
    }
    catch {
        Write-Warn (T "msg.save_license_fail" "Failed to save license data: {0}" @($_.Exception.Message))
    }
}

function Show-LicenseState([object]$Lic) {
    if (-not $Lic) { return }
    Write-Header (T "msg.current_license" "Current License Info:")
    if ($Lic.license_id) { Write-Info (T "msg.license_id" "- License ID: {0}" @($Lic.license_id)) }
    if ($Lic.domain) { Write-Info (T "msg.domain" "- Domain: {0}" @($Lic.domain)) }
    if ($Lic.expiry_date) { Write-Info (T "msg.expiry" "- Expiry Date: {0}" @($Lic.expiry_date)) }
    if ($Lic.db) {
        if ($Lic.db.host) {
            $dispHost = if ($Lic.db.host -eq "localhost") { "premium.zonely.gen.tr" } else { $Lic.db.host }
            Write-Info (T "msg.db_host" "- DB Host: {0}" @($dispHost))
        }
        if ($Lic.db.port) { Write-Info (T "msg.db_port" "- DB Port: {0}" @($Lic.db.port)) }
        if ($Lic.db.username) { Write-Info (T "msg.db_user" "- DB Username: {0}" @($Lic.db.username)) }
        if ($Lic.db.password) { Write-Info (T "msg.db_pass" "- DB Password: {0}" @($Lic.db.password)) }
        if ($Lic.db.dbname) { Write-Info (T "msg.db_name" "- DB Name: {0}" @($Lic.db.dbname)) }
    }
}

function Get-CsrfToken([string]$Base, [string]$Path, [Microsoft.PowerShell.Commands.WebRequestSession]$Session) {
    $uri = Join-Url $Base $Path
    $headers = Get-RequestHeaders
    $resp = Invoke-WebRequest -Uri $uri -WebSession $Session -Method Get -UseBasicParsing -Headers $headers
    if (-not $resp) {
        return @{ Ok = $false; Error = "no_response"; Source = $uri }
    }

    $html = $resp.Content
    if (Test-WafChallenge $html) {
        $challengeUrl = $null
        if ($resp.BaseResponse -and $resp.BaseResponse.ResponseUri) {
            $challengeUrl = $resp.BaseResponse.ResponseUri.AbsoluteUri
        }
        if ($challengeUrl -and $challengeUrl -notlike "*__waf_challenge*") {
            $challengeUrl = Resolve-Location $Base ("/__waf_challenge?ref=" + [Uri]::EscapeDataString($Path))
        }
        if (-not $challengeUrl) {
            $challengeUrl = Resolve-Location $Base ("/__waf_challenge?ref=" + [Uri]::EscapeDataString($Path))
        }

        try {
            $null = Invoke-WebRequest -Uri $challengeUrl -WebSession $Session -Method Get -UseBasicParsing -Headers $headers
            $resp = Invoke-WebRequest -Uri $uri -WebSession $Session -Method Get -UseBasicParsing -Headers $headers
            $html = $resp.Content
        }
        catch {}
    }

    if ([string]::IsNullOrWhiteSpace($html)) {
        return @{ Ok = $false; Error = "empty_body"; Status = $resp.StatusCode; Source = $uri }
    }

    $pattern = "name=['""](?<name>csrf[-_]?token)['""][^>]*value=['""](?<token>[^'""]+)['""]"
    $matches = [regex]::Matches($html, $pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $picked = $null
    foreach ($m in $matches) {
        $name = $m.Groups["name"].Value
        $tokenRaw = $m.Groups["token"].Value
        if (-not $tokenRaw) { continue }
        $token = [System.Net.WebUtility]::HtmlDecode($tokenRaw)
        if (-not $token) { continue }
        if ($name -eq "csrf-token") {
            $picked = @{ FieldName = $name; Token = $token; Source = $uri }
            break
        }
        if (-not $picked) {
            $picked = @{ FieldName = $name; Token = $token; Source = $uri }
        }
    }

    if ($picked) {
        return @{
            Ok        = $true
            FieldName = $picked.FieldName
            Token     = $picked.Token
            Source    = $picked.Source
            Status    = $resp.StatusCode
        }
    }

    if (Test-WafChallenge $html) {
        return @{ Ok = $false; Error = "waf_challenge"; Status = $resp.StatusCode; Source = $uri }
    }

    if (Test-CloudflareChallenge $html) {
        return @{ Ok = $false; Error = "cloudflare"; Status = $resp.StatusCode; Source = $uri }
    }

    return @{ Ok = $false; Error = "token_not_found"; Status = $resp.StatusCode; Source = $uri }
}

function Parse-AuthResponse([string]$Payload) {
    if ([string]::IsNullOrWhiteSpace($Payload)) {
        return @{ Ok = $false; Code = "empty" }
    }
    try {
        $json = $Payload | ConvertFrom-Json
        $status = "$($json.status)".ToLowerInvariant()
        if ($status -eq "success") {
            return @{ Ok = $true; Code = "success" }
        }
        if ($status -eq "tfa_required") {
            return @{ Ok = $false; Code = "tfa_required" }
        }
        return @{ Ok = $false; Code = "failed" }
    }
    catch {
        return @{ Ok = $false; Code = "invalid_json" }
    }
}

function Parse-Json([string]$Payload) {
    if ([string]::IsNullOrWhiteSpace($Payload)) { return $null }
    try { return ($Payload | ConvertFrom-Json) } catch { return $null }
}

function Invoke-ApiGet([string]$Url, [Microsoft.PowerShell.Commands.WebRequestSession]$Session) {
    $headers = Get-RequestHeaders
    try {
        $resp = Invoke-WebRequest -Uri $Url -WebSession $Session -Method Get -Headers $headers -UseBasicParsing
        return @{ Ok = $true; Status = $resp.StatusCode; Content = $resp.Content }
    }
    catch {
        $resp = $_.Exception.Response
        if ($resp -and $resp.GetResponseStream) {
            $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $content = $reader.ReadToEnd()
            return @{ Ok = $false; Status = [int]$resp.StatusCode; Content = $content }
        }
        throw
    }
}

function Invoke-ApiPost([string]$Url, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [hashtable]$Form) {
    $headers = Get-RequestHeaders
    try {
        $resp = Invoke-WebRequest -Uri $Url -WebSession $Session -Method Post -Headers $headers -Body $Form -UseBasicParsing
        return @{ Ok = $true; Status = $resp.StatusCode; Content = $resp.Content }
    }
    catch {
        $resp = $_.Exception.Response
        if ($resp -and $resp.GetResponseStream) {
            $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $content = $reader.ReadToEnd()
            return @{ Ok = $false; Status = [int]$resp.StatusCode; Content = $content }
        }
        throw
    }
}

function Warmup-Session([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session) {
    $paths = @("/profile", "/login", "/")
    foreach ($p in $paths) {
        $url = Join-Url $Base $p
        try {
            $headers = Get-RequestHeaders
            Invoke-WebRequest -Uri $url -WebSession $Session -Method Get -Headers $headers -UseBasicParsing | Out-Null
        }
        catch {}
    }
}

function Normalize-Domain([string]$Domain) {
    if ([string]::IsNullOrWhiteSpace($Domain)) { return "" }
    $d = $Domain.Trim().ToLowerInvariant()
    $d = $d -replace "^https?://", ""
    $d = $d -replace "/.*$", ""
    return $d.Trim()
}

function New-VerifyToken() {
    $bytes = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
}

function Get-CnameTargets([string]$Name) {
    try {
        $records = Resolve-DnsName -Type CNAME -Name $Name -ErrorAction Stop
        $targets = @()
        foreach ($r in $records) {
            if ($r.NameHost) { $targets += $r.NameHost }
        }
        return $targets
    }
    catch {
        return @()
    }
}

function Get-TxtRecords([string]$Name, [string]$Server = "") {
    try {
        if ([string]::IsNullOrWhiteSpace($Server)) {
            $records = Resolve-DnsName -Type TXT -Name $Name -ErrorAction Stop
        }
        else {
            $records = Resolve-DnsName -Type TXT -Name $Name -Server $Server -ErrorAction Stop
        }
        $txts = @()
        foreach ($r in $records) {
            if ($r.Strings) { $txts += $r.Strings }
        }
        return $txts
    }
    catch {
        return @()
    }
}

function Check-TxtOnly([string]$Domain, [string]$Token) {
    $servers = @("", "1.1.1.1", "8.8.8.8")
    $txts = @()
    foreach ($s in $servers) {
        $txts += Get-TxtRecords $Domain $s
    }
    $txts = $txts | Where-Object { $_ } | Select-Object -Unique
    $wantTxt = "ZONELY-" + $Token
    $okTxt = $false
    foreach ($t in $txts) {
        if ($t -and ($t -like ("*" + $wantTxt + "*"))) { $okTxt = $true; break }
    }
    return @{
        ok     = $okTxt
        txt_ok = $okTxt
        txts   = $txts
    }
}

function Get-LicenseList([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session) {
    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Zonely&container=List")
    $resp = Invoke-ApiGet -Url $url -Session $Session
    $json = Parse-Json $resp.Content
    return @{ Status = $resp.Status; Raw = $resp.Content; Data = $json }
}

function Get-LicenseInfo([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [int]$LicenseId) {
    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Zonely&container=Info&licenseId=" + $LicenseId)
    $resp = Invoke-ApiGet -Url $url -Session $Session
    $json = Parse-Json $resp.Content
    return @{ Status = $resp.Status; Raw = $resp.Content; Data = $json }
}

function Update-LicenseDomain([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [int]$LicenseId, [string]$Domain) {
    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Zonely&container=UpdateDomain")
    $form = @{ licenseId = $LicenseId; domain = $Domain }
    $resp = Invoke-ApiPost -Url $url -Session $Session -Form $form
    $json = Parse-Json $resp.Content
    return @{ Status = $resp.Status; Raw = $resp.Content; Data = $json }
}

function Invoke-Buy([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [string]$Domain, [string]$ProductId = "1") {
    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Buys&container=Buy")
    $form = @{
        domainadress  = $Domain
        licenseadress = $Domain
        productid     = $ProductId
    }
    $resp = Invoke-ApiPost -Url $url -Session $Session -Form $form
    return @{ Status = $resp.Status; Raw = $resp.Content }
}

function Start-AutoSetup([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [int]$LicenseId) {
    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Zonely&container=AutoSetup&licenseId=" + $LicenseId)
    $resp = Invoke-ApiGet -Url $url -Session $Session
    $json = Parse-Json $resp.Content
    return @{ Status = $resp.Status; Raw = $resp.Content; Data = $json }
}

function Wait-AutoSetup([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [int]$LicenseId, [int]$TimeoutSeconds = 900) {
    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Zonely&container=Status&licenseId=" + $LicenseId)
    $last = -1
    $announced = $false
    $start = Get-Date
    while ($true) {
        Start-Sleep -Seconds 3
        $resp = Invoke-ApiGet -Url $url -Session $Session
        $json = Parse-Json $resp.Content
        $progress = if ($json -and $json.progress -ne $null) { [int]$json.progress } else { -1 }
        if ($progress -ge 0 -and $progress -ne $last) {
            Write-ProgressBar -Percent $progress -Label (T "label.setup" "Setup")
            $last = $progress
        }
        elseif (-not $announced -and $progress -lt 0) {
            Write-Info (T "msg.setup_wait" "Setup started. Waiting for progress...")
            $announced = $true
        }
        if (((Get-Date) - $start).TotalSeconds -ge $TimeoutSeconds) {
            Write-Host ""
            Write-Warn (T "msg.setup_timeout" "Installation might be timing out.")
            return $false
        }
        if ($progress -ge 100) { Write-Host ""; return $true }
        if ($progress -eq 0) { Write-Host ""; return $false }
    }
}

function Show-LicenseList([object[]]$Licenses) {
    if (-not $Licenses -or $Licenses.Count -eq 0) {
        Write-Warn (T "msg.no_licenses" "No licenses found.")
        return
    }
    Write-Header (T "msg.licenses_header" "-- Your Licenses --")
    foreach ($l in $Licenses) {
        $id = $l.id
        $domain = $l.domainAdress
        $exp = $l.expiry_date
        if (-not $exp) { $exp = "-" }
        Write-Host " #$id " -NoNewline -ForegroundColor Yellow
        Write-Host (T "msg.license_line" "| Domain: {0} | Expiry: {1}" @($domain, $exp)) -ForegroundColor White
    }
}

function Select-LicenseId([object[]]$Licenses, [int]$DefaultId = 0) {
    if ($DefaultId -gt 0) {
        $ans = Read-Input (T "prompt.license_id_default" ("License ID") @($DefaultId))
        if ([string]::IsNullOrWhiteSpace($ans)) { return $DefaultId }
    }
    else {
        $ans = Read-Input (T "prompt.license_id" "License ID")
    }
    $id = 0
    [int]::TryParse($ans, [ref]$id) | Out-Null
    return $id
}

function Download-SqlDump([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [int]$LicenseId, [string]$OutFile) {
    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Zonely&container=SQLDump&licenseId=" + $LicenseId)
    $headers = Get-RequestHeaders
    try {
        Invoke-WebRequest -Uri $url -WebSession $Session -Method Get -Headers $headers -UseBasicParsing -OutFile $OutFile | Out-Null
        if (Test-Path $OutFile) {
            $len = (Get-Item $OutFile).Length
            if ($len -gt 0) {
                Write-Ok (T "msg.sql_ok" "SQL dump downloaded to: {0}" @($OutFile))
                return $true
            }
        }
        Write-Warn (T "msg.sql_empty" "SQL dump failed (empty file).")
        return $false
    }
    catch {
        Write-Err (T "msg.sql_error" "SQL dump error: {0}" @($_.Exception.Message))
        return $false
    }
}

function Build-AuthMeConfig([object]$Lic) {
    if (-not $Lic) { return "" }
    $dbHost = "premium.zonely.gen.tr"
    $dbPort = "3306"
    $dbUser = $Lic.db.username
    $dbPass = $Lic.db.password
    $dbName = $Lic.db.dbname
    @"
DataSource:
    backend: MYSQL 
    caching: false
    mySQLHost: $dbHost
    mySQLPort: $dbPort
    mySQLUseSSL: false
    mySQLCheckServerCertificate: true
    mySQLUsername: $dbUser
    mySQLPassword: $dbPass
    mySQLDatabase: $dbName
    mySQLTablename: userslist
    mySQLColumnId: id
    mySQLColumnName: subname
    mySQLRealName: nick
    mySQLColumnPassword: password
    mySQLColumnSalt: ''
    mySQLColumnEmail: email
    mySQLColumnLogged: authme_logged
    mySQLColumnHasSession: authme_session
    mySQLtotpKey: totp
    mySQLColumnIp: ip
    mySQLColumnLastLogin: authme_lastlogin
    mySQLColumnRegisterDate: authme_created_at
    mySQLColumnRegisterIp: authme_regip
    mySQLlastlocX: x
    mySQLlastlocY: y
    mySQLlastlocZ: z
    mySQLlastlocWorld: world
    mySQLlastlocYaw: yaw
    mySQLlastlocPitch: pitch
    poolSize: 10
    maxLifetime: 1140000
"@
}

function Save-AuthMeConfig([object]$Lic, [string]$FilePath) {
    $cfg = Build-AuthMeConfig $Lic
    if ([string]::IsNullOrWhiteSpace($cfg)) {
        Write-Warn (T "msg.authme_build_fail" "Could not build AuthMe config.")
        return
    }
    Set-Content -Path $FilePath -Value $cfg -Encoding UTF8
    Write-Ok (T "msg.authme_saved" "AuthMe config saved to: {0}" @($FilePath))
}

function Get-RememberMeTokenFromCookies([string]$FilePath) {
    if (-not $FilePath -or -not (Test-Path $FilePath)) { return "" }
    try {
        $raw = Get-Content -Path $FilePath -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { return "" }
        $items = $raw | ConvertFrom-Json
        if (-not $items) { return "" }
        $cands = @()
        foreach ($c in $items) {
            if ($c.name -ne "rememberMe") { continue }
            $exp = [DateTime]::MinValue
            if ($c.expires) {
                try { $exp = [DateTime]::Parse($c.expires) } catch {}
            }
            $cands += [pscustomobject]@{ value = $c.value; expires = $exp }
        }
        if ($cands.Count -eq 0) { return "" }
        return ($cands | Sort-Object expires -Descending | Select-Object -First 1).value
    }
    catch {
        return ""
    }
}

function Get-RememberMeTokenFromSession([Microsoft.PowerShell.Commands.WebRequestSession]$Session, [string]$Base) {
    try {
        $uri = [Uri]$Base
        $cookies = $Session.Cookies.GetCookies($uri)
        $cands = @()
        foreach ($c in $cookies) {
            if ($c.Name -ne "rememberMe") { continue }
            $exp = if ($c.Expires -gt [DateTime]::MinValue) { $c.Expires } else { [DateTime]::MinValue }
            $cands += [pscustomobject]@{ value = $c.Value; expires = $exp }
        }
        if ($cands.Count -eq 0) { return "" }
        return ($cands | Sort-Object expires -Descending | Select-Object -First 1).value
    }
    catch {
        return ""
    }
}

function Open-Url([string]$Url) {
    try {
        $xdg = Get-Command xdg-open -ErrorAction SilentlyContinue
        if ($xdg) { & $xdg.Path $Url | Out-Null; return $true }
        $open = Get-Command open -ErrorAction SilentlyContinue
        if ($open) { & $open.Path $Url | Out-Null; return $true }
        Start-Process $Url | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Start-DiscordVerify([string]$Base, [string]$RememberToken) {
    if ([string]::IsNullOrWhiteSpace($RememberToken)) {
        Write-Warn (T "msg.discord_token_missing" "rememberMe token not found. Please login first.")
        return
    }
    $tok = [Uri]::EscapeDataString($RememberToken)
    $url = Join-Url $Base ("/discord-verify-router?token=" + $tok + "&action=login")
    Write-Info (T "msg.discord_opening" "Opening Discord verification: {0}" @($url))
    if (-not (Open-Url $url)) { Write-Warn (T "msg.browser_open_fail" "Could not open browser.") }
}

function Invoke-Login([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [string]$Identifier, [string]$Password, [bool]$Remember) {
    $csrf = Get-CsrfToken $Base "/login" $Session
    if (-not $csrf.Ok -and $csrf.Error -eq "cloudflare") {
        Write-Warn (T "msg.cloudflare" "Cloudflare detected (CSRF page).")
        $cookieHeader = Read-Input (T "prompt.cookie_header" "Please enter Browser Cookie Header (cf_clearance=...; __cf_bm=...)")
        if (-not [string]::IsNullOrWhiteSpace($cookieHeader)) {
            Add-CookiesFromHeader $Session $Base $cookieHeader
            $csrf = Get-CsrfToken $Base "/login" $Session
        }
    }
    if (-not $csrf.Ok) {
        Write-Err (T "msg.csrf_failed" "Failed to get CSRF token. Error: {0}" @($csrf.Error))
        return $false
    }

    $form = @{
        mail                    = $Identifier
        username                = $Identifier
        password                = $Password
        rememberMe              = $(if ($Remember) { "true" } else { "false" })
        "csrf-token"            = $csrf.Token
        "csrf_token"            = $csrf.Token
        "cf-turnstile-response" = ""
    }
    $form[$csrf.FieldName] = $csrf.Token

    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Login&container=LoginAddController")
    $headers = Get-RequestHeaders
    $headers["Referer"] = "$($csrf.Source)"
    $resp = Invoke-WebRequest -Uri $url -WebSession $Session -Method Post -Body $form -Headers $headers -UseBasicParsing
    
    $result = Parse-AuthResponse $resp.Content
    if ($result.Ok) {
        Write-Ok (T "msg.login_success" "Login successful.")
        $cookiePath = Resolve-PathAbsolute $CookieFile
        Save-Cookies -Session $Session -Base $Base -FilePath $cookiePath
        return $true
    }
    if ($result.Code -eq "tfa_required") {
        Write-Warn (T "msg.login_2fa" "Two-factor authentication required. Please complete login on the website.")
    }
    elseif ($result.Code -eq "invalid_json") {
        Write-Err (T "msg.unexpected_response" "Unexpected response from server.")
    }
    else {
        Write-Err (T "msg.login_failed" "Login failed.")
    }
    return $false
}

function Invoke-Register([string]$Base, [Microsoft.PowerShell.Commands.WebRequestSession]$Session, [string]$Email, [string]$Password, [string]$Confirm, [string]$FirstName, [string]$LastName) {
    $csrf = Get-CsrfToken $Base "/register" $Session
    if (-not $csrf.Ok) {
        Write-Err (T "msg.csrf_failed" "Failed to get CSRF token. Error: {0}" @($csrf.Error))
        return $false
    }

    $first = $FirstName.Trim()
    $last = $LastName.Trim()

    $form = @{
        subname                 = $first
        lastname                = $last
        mail                    = $Email
        email                   = $Email
        password                = $Password
        password_confirm        = $Confirm
        cpassword               = $Confirm
        rememberMe              = "true"
        registeruserslist       = "1"
        "csrf-token"            = $csrf.Token
        "csrf_token"            = $csrf.Token
        "cf-turnstile-response" = ""
    }
    $form[$csrf.FieldName] = $csrf.Token

    $url = Join-Url $Base ($script:ApiEndpoint + "?main=Register&container=RegisterAddController")
    $headers = Get-RequestHeaders
    $headers["Referer"] = "$($csrf.Source)"
    $resp = Invoke-WebRequest -Uri $url -WebSession $Session -Method Post -Body $form -Headers $headers -UseBasicParsing
    
    $result = Parse-AuthResponse $resp.Content
    if ($result.Ok) {
        Write-Ok (T "msg.register_success" "Registration successful.")
        $cookiePath = Resolve-PathAbsolute $CookieFile
        Save-Cookies -Session $Session -Base $Base -FilePath $cookiePath
        return $true
    }
    if ($result.Code -eq "invalid_json") {
        Write-Err (T "msg.unexpected_response" "Unexpected response from server.")
    }
    else {
        Write-Err (T "msg.register_failed" "Registration failed.")
    }
    return $false
}


function Invoke-ArrowMenu([string]$Title, [System.Collections.Specialized.OrderedDictionary]$Options) {
    $keys = $Options.Keys | ForEach-Object { $_ }
    $count = $keys.Count
    $sel = 0
    
    try { [Console]::CursorVisible = $false } catch {}

    while ($true) {
        Draw-Header
        Write-Header $Title
        Write-Host (T "ui.use_arrows" "Use UP/DOWN arrows to navigate, ENTER to select.") -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 0; $i -lt $count; $i++) {
            $label = $keys[$i]
            if ($i -eq $sel) {
                Write-Host " > $label" -ForegroundColor Cyan
            }
            else {
                Write-Host "   $label" -ForegroundColor Gray
            }
        }
        
        $k = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $vk = $k.VirtualKeyCode
        if ($vk -eq 38) {
            $sel--
            if ($sel -lt 0) { $sel = $count - 1 }
        }
        elseif ($vk -eq 40) {
            $sel++
            if ($sel -ge $count) { $sel = 0 }
        }
        elseif ($vk -eq 13) {
            try { [Console]::CursorVisible = $true } catch {}
            return $Options[$keys[$sel]]
        }
    }
}

function Show-Menu-Unauth {
    return Invoke-ArrowMenu (T "menu.welcome" "Welcome! Please login or register.") ([ordered]@{
            (T "menu.login" "Login")       = "1"
            (T "menu.register" "Register") = "2"
            (T "menu.exit" "Exit")         = "9"
        })
}

function Show-Menu-Auth {
    return Invoke-ArrowMenu (T "menu.main" "Main Menu") ([ordered]@{
            (T "menu.list" "List Licenses")            = "1"
            (T "menu.details" "View License Details")  = "2"
            (T "menu.update_domain" "Update Domain")   = "3"
            (T "menu.autosetup" "Start Auto Setup")    = "4"
            (T "menu.sqldump" "Download SQL Dump")     = "5"
            (T "menu.authme" "Generate AuthMe Config") = "6"
            (T "menu.dbinfo" "View DB Credentials")    = "7"
            (T "menu.buy" "Buy New License")           = "8"
            (T "menu.discord" "Discord Role Verify")   = "10"
            (T "menu.logout" "Logout")                 = "0"
            (T "menu.exit" "Exit")                     = "9"
        })
}

function Select-Language {
    $config = Load-Config
    if ($config -and $config.Language -and $script:Locales.Contains($config.Language)) {
        $script:Lang = $config.Language
        return
    }

    $opts = [ordered]@{}
    foreach ($k in $script:Locales.Keys) {
        $label = $script:Locales[$k]
        $opts[$label] = $k
    }
    $choice = Invoke-ArrowMenu (T "ui.select_language" "Select Language") $opts
    if ($choice) { 
        $script:Lang = $choice 
        $newConfig = if ($config) { $config } else { @{} }
        $newConfig.Language = $choice
        Save-Config $newConfig
    }
}

function Run-Main {
    Set-ConsoleSize
    try {
        $ws = $host.UI.RawUI.WindowSize
        if ($ws.Width -lt 120 -or $ws.Height -lt 30) {
            Write-Warn (T "msg.size_warning" "Window size could not be adjusted. If you are using Windows Terminal/VSCode, resize the window manually or run from classic CMD for best view.")
            Start-Sleep -Milliseconds 1200
        }
    }
    catch {}
    Select-Language
    Invoke-AutoUpdate
    Show-Loading (T "ui.loading" "Loading, please wait...")
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $script:BaseUrl = Get-BaseUrl
    if ([string]::IsNullOrWhiteSpace($script:BaseUrl)) {
        Write-Err (T "msg.base_url_missing" "Base URL not set. Configure BaseUrl/BaseUrlEnc or env vars.")
        return
    }
    $cookiePath = Resolve-PathAbsolute $CookieFile
    if ($CookieFile -eq "cookies.json") {
        $legacyCookie = Resolve-PathAbsolute "zonely.cookies.json"
        if (-not (Test-Path $cookiePath) -and (Test-Path $legacyCookie)) {
            try { Copy-Item -Path $legacyCookie -Destination $cookiePath -Force } catch {}
        }
    }
    if ($cookiePath) { Load-Cookies -Session $session -FilePath $cookiePath }
    
    $licensePath = Resolve-PathAbsolute $LicenseFile
    if ($LicenseFile -eq "license.json") {
        $legacyLic = Resolve-PathAbsolute "zonely-license.json"
        if (-not (Test-Path $licensePath) -and (Test-Path $legacyLic)) {
            try { Copy-Item -Path $legacyLic -Destination $licensePath -Force } catch {}
        }
    }
    $licenseState = if ($licensePath) { Load-LicenseState $licensePath } else { $null }

    Warmup-Session -Base $BaseUrl -Session $session
    $probe = Get-LicenseList -Base $BaseUrl -Session $session
    $authed = ($probe.Data -and $probe.Data.ok)

    while ($true) {
        if (-not $authed) {
            $choice = Show-Menu-Unauth
            Draw-Header
            
            if ($choice -eq "9") { exit }
            
            if ($choice -eq "1") {
                $id = Read-Input (T "prompt.email" "Email")
                $pw = Read-Input (T "prompt.password" "Password") $true
                if (Invoke-Login -Base $BaseUrl -Session $session -Identifier $id -Password $pw -Remember $true) {
                    $authed = $true
                }
                else {
                    Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                }
            }
            elseif ($choice -eq "2") {
                $first = Read-Input (T "prompt.first_name" "First Name")
                $last = Read-Input (T "prompt.last_name" "Last Name")
                $email = Read-Input (T "prompt.email" "Email")
                $pw1 = Read-Input (T "prompt.password" "Password") $true
                $pw2 = Read-Input (T "prompt.confirm_password" "Confirm Password") $true
                
                if ($pw1 -ne $pw2) {
                    Write-Warn (T "msg.register_mismatch" "Passwords do not match.")
                }
                else {
                    if (Invoke-Register -Base $BaseUrl -Session $session -Email $email -Password $pw1 -Confirm $pw2 -FirstName $first -LastName $last) {
                        $authed = $true
                        Write-Ok (T "msg.register_auto" "Registration successful! Logged in automatically.")
                    }
                }
                Read-Input (T "prompt.press_enter" "Press Enter to continue...")
            }
        }
        else {
            $choice = Show-Menu-Auth
            Draw-Header
            
            if ($choice -eq "9") { exit }
            if ($choice -eq "0") {
                $authed = $false
                $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                Write-Warn (T "msg.logged_out" "Logged out.")
                Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                continue
            }

            $licenseOps = @("1", "2", "3", "4", "5", "6", "7")
            if ($licenseOps -contains $choice) {
                $list = Get-LicenseList -Base $BaseUrl -Session $session
                if (-not ($list.Data -and $list.Data.ok)) {
                    Write-Err (T "msg.list_fail" "Failed to retrieve license list. Session might have expired.")
                    $authed = $false
                    Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                    continue
                }
                
                $licenses = $list.Data.licenses
                
                if ($choice -eq "1") {
                    Show-LicenseList $licenses
                    Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                    continue
                }

                Show-LicenseList $licenses
                $defaultId = if ($licenseState -and $licenseState.license) { [int]$licenseState.license.license_id } else { 0 }
                $licenseId = Select-LicenseId -Licenses $licenses -DefaultId $defaultId
                
                if ($licenseId -le 0) {
                    Write-Warn (T "msg.invalid_license" "That is not a valid License ID.")
                    Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                    continue
                }

                if ($choice -eq "2") {
                    $info = Get-LicenseInfo -Base $BaseUrl -Session $session -LicenseId $licenseId
                    if ($info.Data -and $info.Data.ok -and $info.Data.license) {
                        $lic = $info.Data.license
                        $licenseState = [pscustomobject]@{
                            saved_at = (Get-Date).ToString("o")
                            license  = [pscustomobject]@{
                                license_id  = $lic.id
                                domain      = $lic.domainAdress
                                product_id  = $lic.productid
                                expiry_date = $lic.expiry_date
                                db          = [pscustomobject]@{
                                    host     = $lic.host
                                    port     = $lic.port
                                    username = $lic.username
                                    password = $lic.db_password
                                    dbname   = $lic.dbname
                                }
                            }
                        }
                        if ($licensePath) { Save-LicenseState -FilePath $licensePath -State $licenseState }
                        Show-LicenseState $licenseState.license
                    }
                    else {
                        Write-Warn (T "msg.license_detail_fail" "Could not fetch license details.")
                    }
                }
                elseif ($choice -eq "3") {
                    $newDomain = Normalize-Domain (Read-Input (T "prompt.new_domain" "Enter New Domain Name"))
                    if (-not $newDomain) {
                        Write-Warn (T "msg.invalid_domain" "Invalid domain name.")
                    }
                    else {
                        $token = New-VerifyToken
                        Write-Header (T "msg.txt_required" "TXT Verification Required:")
                        Write-Host (T "msg.txt_add" "Add this TXT record to your domain DNS:") -ForegroundColor Yellow
                        Write-Host (T "msg.txt_type" "Type: TXT")
                        Write-Host (T "msg.txt_host" "Host: @")
                        Write-Host (T "msg.txt_value" "Value: ZONELY-{0}" @($token)) -ForegroundColor Cyan
                        
                        if (Read-YesNo (T "msg.txt_added" "Have you added the TXT record?")) {
                            Write-Info (T "msg.verifying" "Verifying...")
                            $verified = $false
                            while ($true) {
                                $check = Check-TxtOnly -Domain $newDomain -Token $token
                                if ($check.ok) {
                                    Write-Ok (T "msg.txt_verified" "TXT Verified!")
                                    $verified = $true
                                    break
                                }
                                Write-Warn (T "msg.txt_failed" "TXT verification failed.")
                                if (-not (Read-YesNo (T "msg.retry_verify" "Retry verification?"))) { break }
                            }
                            if (-not $verified) {
                                Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                                continue
                            }
                        }
                        else {
                            Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                            continue
                        }

                        $upd = Update-LicenseDomain -Base $BaseUrl -Session $session -LicenseId $licenseId -Domain $newDomain
                        if ($upd.Data -and $upd.Data.ok) {
                            Write-Ok (T "msg.domain_updated" "Domain updated successfully.")
                        }
                        else {
                            Write-Err (T "msg.domain_update_fail" "Failed to update domain.")
                        }
                    }

                }
                elseif ($choice -eq "4") {
                    Write-Info (T "msg.setup_starting" "Starting Auto Setup...")
                    $start = Start-AutoSetup -Base $BaseUrl -Session $session -LicenseId $licenseId
                    if ($start.Data -and $start.Data.ok) {
                        Wait-AutoSetup -Base $BaseUrl -Session $session -LicenseId $licenseId | Out-Null
                        Write-Ok (T "msg.setup_finished" "Setup process finished.")
                    }
                    else {
                        Write-Err (T "msg.setup_start_fail" "Could not start auto setup.")
                    }
                }
                elseif ($choice -eq "5") {
                    $out = Join-Path $PSScriptRoot ("dump_" + $licenseId + ".sql")
                    Download-SqlDump -Base $BaseUrl -Session $session -LicenseId $licenseId -OutFile $out | Out-Null
                }
                elseif ($choice -eq "6") {
                    $info = Get-LicenseInfo -Base $BaseUrl -Session $session -LicenseId $licenseId
                    if ($info.Data -and $info.Data.ok -and $info.Data.license) {
                        $lic = $info.Data.license
                        $licObj = [pscustomobject]@{
                            db = [pscustomobject]@{
                                host     = $lic.host
                                port     = $lic.port
                                username = $lic.username
                                password = $lic.db_password
                                dbname   = $lic.dbname
                            }
                        }
                        $out = Join-Path $PSScriptRoot ("authme-config_" + $licenseId + ".yml")
                        Save-AuthMeConfig -Lic $licObj -FilePath $out
                    }
                    else {
                        Write-Warn (T "msg.authme_info_fail" "Could not fetch license info for config.")
                    }
                }
                elseif ($choice -eq "7") {
                    $info = Get-LicenseInfo -Base $BaseUrl -Session $session -LicenseId $licenseId
                    if ($info.Data -and $info.Data.ok -and $info.Data.license) {
                        $lic = $info.Data.license
                        $dispHost = if ($lic.host -eq "localhost") { "premium.zonely.gen.tr" } else { $lic.host }
                        Write-Header (T "msg.db_info" "Database Information:")
                        Write-Info (T "msg.db_host_line" "Host: {0}" @($dispHost))
                        Write-Info (T "msg.db_port_line" "Port: {0}" @($lic.port))
                        Write-Info (T "msg.db_user_line" "Username: {0}" @($lic.username))
                        Write-Info (T "msg.db_pass_line" "Password: {0}" @($lic.db_password))
                        Write-Info (T "msg.db_name_line" "DB Name: {0}" @($lic.dbname))
                        Write-Info (T "msg.db_phpmyadmin" "phpMyAdmin: {0}" @("https://phpmyadmin.zonely.gen.tr:8443/phpMyAdmin/"))
                    }
                    else {
                        Write-Warn (T "msg.license_detail_fail" "Could not fetch license details.")
                    }
                }
                Read-Input (T "prompt.press_enter" "Press Enter to continue...")
            }
            
            if ($choice -eq "8") {
                $domainInput = Read-Input (T "prompt.buy_domain" "Enter Domain to Buy License For")
                $domain = Normalize-Domain $domainInput
                if (-not $domain) {
                    Write-Err (T "msg.invalid_domain" "Invalid domain.")
                }
                else {
                    $verifyToken = New-VerifyToken
                    Write-Header (T "msg.dns_required" "DNS Verification Required")
                    Write-Info (T "msg.dns_add" "Please add these records to your DNS panel:")
                    Write-Info (T "msg.cname_root" "CNAME  {0}       ->  premium.zonely.gen.tr (Proxy Enabled)" @($domain))
                    Write-Info (T "msg.cname_www" "CNAME  www.{0}   ->  premium.zonely.gen.tr (Proxy Enabled)" @($domain))
                    Write-Host (T "msg.txt_record" "TXT    {0}       ->  ZONELY-{1}" @($domain, $verifyToken)) -ForegroundColor Cyan
                     
                    if (Read-YesNo (T "msg.dns_added" "Have you added the DNS records?")) {
                        while ($true) {
                            $check = Check-TxtOnly -Domain $domain -Token $verifyToken
                            if ($check.ok) {
                                Write-Ok (T "msg.txt_verified" "TXT Verified!")
                                break
                            }
                            Write-Warn (T "msg.dns_failed" "Verification failed. Check your DNS.")
                            if (-not (Read-YesNo (T "msg.retry" "Retry?"))) { break }
                        }
                        if (-not $check.ok) {
                            Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                            continue
                        }
                    }
                    else {
                        Read-Input (T "prompt.press_enter" "Press Enter to continue...")
                        continue
                    }
                     
                    Write-Info (T "msg.creating_license" "Creating license...")
                    $buy = Invoke-Buy -Base $BaseUrl -Session $session -Domain $domain -ProductId "3"
                    $buyRaw = ($buy.Raw | Out-String).Trim()
                     
                    if ($buyRaw -eq "successful") {
                        Write-Ok (T "msg.license_purchased" "License purchased successfully!")
                        Write-Info (T "msg.starting_initial" "Starting initial setup...")
                        $list = Get-LicenseList -Base $BaseUrl -Session $session
                        $licenseId = 0
                        if ($list.Data -and $list.Data.ok -and $list.Data.licenses) {
                            $norm = Normalize-Domain $domain
                            $match = $list.Data.licenses | Where-Object { (Normalize-Domain $_.domainAdress) -eq $norm } | Select-Object -First 1
                            if ($match) { $licenseId = [int]$match.id }
                        }
                        if ($licenseId -gt 0) {
                            Start-AutoSetup -Base $BaseUrl -Session $session -LicenseId $licenseId | Out-Null
                            Write-Ok (T "msg.license_setup_started" "License setup started. It will be ready in ~30 minutes.")
                        }
                    }
                    else {
                        Write-Err (T "msg.purchase_failed" "Purchase failed.")
                    }
                }
                Read-Input (T "prompt.press_enter" "Press Enter to continue...")
            }

            if ($choice -eq "10") {
                $remember = Get-RememberMeTokenFromCookies $cookiePath
                if (-not $remember) {
                    $remember = Get-RememberMeTokenFromSession -Session $session -Base $BaseUrl
                }
                Start-DiscordVerify -Base $BaseUrl -RememberToken $remember
                Read-Input (T "msg.discord_opened" "Discord verification opened. Press Enter when complete...")
            }
        }
    }
}

try {
    Run-Main
}
catch {
    Write-Err (T "msg.fatal_error" "Fatal Error: {0}" @($_.Exception.Message))
    exit 1
}
