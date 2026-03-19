#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║    TERMUX SİSTEM YÖNETİCİSİ v5.0 - NİHAİ ULTRA SÜRÜM      ║
# ║    Samsung Galaxy — 53×28 Terminal Optimizasyonlu    ║
# ║    ✅ 255 Fonksiyon | 11 Modül | 200+ CLI Komutu           ║
# ║    Tüm sürümlerin en iyi özellikleri birleştirildi          ║
# ╚══════════════════════════════════════════════════════════════╝
#
# KULLANIM:
#   bash termux_v5.sh              → İnteraktif menü
#   bash termux_v5.sh <komut>      → Doğrudan CLI
#   bash termux_v5.sh yardim       → Tüm komutlar
#
# KURULUM:
#   chmod +x termux_v5.sh
#   echo "alias tm='bash ~/termux_v5.sh'" >> ~/.bashrc && source ~/.bashrc
#
# GEREKSİNİMLER (isteğe bağlı, kurulunca daha fazla özellik):
#   pkg install jq git curl nmap openssl traceroute termux-api

set -o pipefail

# ─── RENK TANIMLARI ─────────────────────────────────────────
KIRMIZI='\033[0;31m'
YESIL='\033[0;32m'
SARI='\033[1;33m'
MAVI='\033[0;34m'
MOR='\033[0;35m'
TURKUAZ='\033[0;36m'
BEYAZ='\033[1;37m'
GRI='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'

# ─── YAPILANDIRMA ────────────────────────────────────────────
KONFIG_DIZINI="$HOME/.termux_yonetici"
GECMIS_DOSYA="$KONFIG_DIZINI/gecmis/son_scriptler.txt"
FAVORI_DOSYA="$KONFIG_DIZINI/favoriler/scriptler.txt"
LOG_DOSYA="$KONFIG_DIZINI/loglar/sistem.log"
YEDEK_KOKU="$KONFIG_DIZINI/yedekler"
PAKET_LISTESI="$KONFIG_DIZINI/paketler.txt"
ALIAS_LISTESI="$KONFIG_DIZINI/aliaslar.txt"
PROJE_LISTESI="$KONFIG_DIZINI/projeler.txt"
ISTATISTIK_DOSYASI="$KONFIG_DIZINI/istatistik.json"
ALIAS_YEDEK="$KONFIG_DIZINI/alias_yedek"
ALIAS_GRUPLAR="$KONFIG_DIZINI/alias_gruplar.txt"
ALIAS_TETIKLEYICI="$KONFIG_DIZINI/alias_tetikleyici.txt"

# Gerekli dizinleri oluştur
mkdir -p "$KONFIG_DIZINI" \
         "$(dirname "$GECMIS_DOSYA")" \
         "$(dirname "$FAVORI_DOSYA")" \
         "$(dirname "$LOG_DOSYA")" \
         "$YEDEK_KOKU" \
         "$ALIAS_YEDEK" 2>/dev/null

# ─── YARDIMCI FONKSİYONLAR ──────────────────────────────────

_log() {
    local seviye="$1"; shift
    local mesaj="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$seviye] $mesaj" >> "$LOG_DOSYA" 2>/dev/null
    [ "$seviye" = "HATA" ] && echo -e "${KIRMIZI}${BOLD}[HATA]${NC} ${KIRMIZI}$mesaj${NC}" >&2
    return 0
}

_baslik() {
    local renk="$1"
    local baslik="$2"
    clear
    echo -e "${renk}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    printf "${renk}║${NC}  ${BEYAZ}%-54s${NC}${renk}║${NC}\n" "$baslik"
    echo -e "${renk}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

_bekle() {
    echo ""
    echo -n -e "${GRI}[ Devam etmek için Enter'a basın... ]${NC}"
    read -r < /dev/tty
}

_onay() {
    echo -n -e "${SARI}${BOLD}$*${NC} ${YESIL}(e)${NC}/${KIRMIZI}(h)${NC}: "
    read -r cevap < /dev/tty
    [[ "$cevap" = "e" || "$cevap" = "E" || "$cevap" = "evet" || "$cevap" = "EVET" ]]
}

_hata() {
    echo -e "${KIRMIZI}${BOLD}[HATA]${NC} ${KIRMIZI}$*${NC}" >&2
    _log "HATA" "$*"
    return 1
}

_basari() {
    echo -e "${YESIL}${BOLD}[OK]${NC} ${YESIL}$*${NC}"
    _log "BASARI" "$*"
    return 0
}

_bilgi()  { echo -e "${TURKUAZ}[i]${NC} ${TURKUAZ}$*${NC}"; }
_uyari()  { echo -e "${SARI}[!]${NC} ${SARI}$*${NC}"; _log "UYARI" "$*"; }
_ayirac() { echo -e "${GRI}──────────────────────────────────────────────────────────${NC}"; }

# Dosya/dizin var mı kontrolü
_dosya_var_mi() {
    local yol="${1/#\~/$HOME}"
    [ -e "$yol" ]
}

# Tilde (~) genişletme
_path_genislet() {
    echo "${1/#\~/$HOME}"
}

# Durum çubuğu - ana menüde gösterilir
_durum_satiri() {
    local ram disk paket script_say
    ram=$(free -h 2>/dev/null | awk '/^Mem:?/{print $3"/"$2}' || echo "N/A")
    disk=$(df -h ~ 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}' || echo "N/A")
    paket=$(pkg list-installed 2>/dev/null | wc -l || echo 0)
    script_say=$(find "$HOME" -maxdepth 4 -name "*.sh" -type f 2>/dev/null | wc -l || echo 0)
    echo -e "  ${GRI}📊 RAM:${BEYAZ}$ram${GRI} | 💾 Disk:${BEYAZ}$disk${GRI} | 📦 Paket:${BEYAZ}$paket${GRI} | 📜 Script:${BEYAZ}$script_say${NC}"
}

# Termux-API var mı?
_api_kontrol() {
    if ! command -v termux-battery-status &>/dev/null; then
        _hata "termux-api yüklü değil!"
        _bilgi "Kurmak için: pkg install termux-api"
        _bilgi "Play Store'dan 'Termux:API' uygulamasını da yükleyin."
        return 1
    fi
    return 0
}

# pip komutunu bul (pip3 öncelikli)
_pip_cmd() {
    command -v pip3 2>/dev/null || command -v pip 2>/dev/null || echo ""
}

# Script geçmişine kaydet (100 kayıt)
_gecmise_kaydet() {
    local script="$1" mod="${2:-normal}"
    mkdir -p "$(dirname "$GECMIS_DOSYA")"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$script|$mod" >> "$GECMIS_DOSYA" 2>/dev/null
    tail -100 "$GECMIS_DOSYA" > "${GECMIS_DOSYA}.tmp" 2>/dev/null \
        && mv "${GECMIS_DOSYA}.tmp" "$GECMIS_DOSYA" 2>/dev/null
    _log "BILGI" "Script çalıştırıldı: $script (mod: $mod)"
}

# İstatistik güncelle
_istatistik_guncelle() {
    local script_adi
    script_adi=$(basename "$1")
    local gecici="/tmp/istatistik_$$.tmp"
    if [ -f "$ISTATISTIK_DOSYASI" ] && command -v jq &>/dev/null; then
        jq --arg k "$script_adi" '.[$k] = ((.[$k] // 0) + 1)' \
            "$ISTATISTIK_DOSYASI" > "$gecici" 2>/dev/null \
            && mv "$gecici" "$ISTATISTIK_DOSYASI" 2>/dev/null
    else
        echo "$script_adi" >> "${ISTATISTIK_DOSYASI}.txt" 2>/dev/null
    fi
}

# ============================================================
# MODÜL 1 — PAKET YÖNETİMİ (18 FONKSİYON)
# ============================================================

paket_listele() {
    _bilgi "Yüklü paketler listeleniyor..."
    pkg list-installed 2>/dev/null | sort | column -t 2>/dev/null | less -R
    _log "BILGI" "Paket listesi görüntülendi"
}

paket_sayisi() {
    local s
    s=$(pkg list-installed 2>/dev/null | wc -l)
    echo -e "${YESIL}${BOLD}Yüklü paket sayısı:${NC} ${BEYAZ}$s${NC}"
    _log "BILGI" "Paket sayısı: $s"
}

paket_guncelle_kontrol() {
    _bilgi "Güncellenebilir paketler kontrol ediliyor..."
    local g
    g=$(pkg list-upgradable 2>/dev/null || pkg list-updatable 2>/dev/null)
    if [ -n "$g" ]; then
        echo "$g"
        local s
        s=$(echo "$g" | wc -l)
        _uyari "$s güncelleme mevcut!"
    else
        _basari "Tüm paketler güncel."
    fi
}

paket_guncelle_tek() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Güncellenecek paket: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _bilgi "Güncelleniyor: $p"
    if pkg upgrade "$p" -y 2>&1; then
        _basari "$p güncellendi."
    else
        _hata "$p güncellenemedi."
        return 1
    fi
}

paket_guncelle_tumu() {
    _bilgi "Tüm paketler güncelleniyor..."
    if pkg update -y && pkg upgrade -y; then
        _basari "Tüm paketler güncellendi."
    else
        _hata "Güncelleme sırasında hata oluştu."
        return 1
    fi
}

paket_ara() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Arama terimi: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Arama terimi boş!"; return 1; }
    _bilgi "Aranıyor: '$p'"
    pkg search "$p" 2>/dev/null | less -R
}

paket_kur() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Yüklenecek paket: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _onay "'$p' kurulsun mu?" || return 0
    _bilgi "Yükleniyor: $p"
    if pkg install -y "$p" 2>&1; then
        _basari "$p yüklendi."
        pkg list-installed 2>/dev/null > "$PAKET_LISTESI"
    else
        _hata "$p yüklenemedi."
        return 1
    fi
}

paket_kaldir() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Kaldırılacak paket: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _onay "'$p' kaldırılsın mı?" || return 0
    _bilgi "Kaldırılıyor: $p"
    if pkg uninstall -y "$p" 2>&1; then
        _basari "$p kaldırıldı."
        pkg list-installed 2>/dev/null > "$PAKET_LISTESI"
    else
        _hata "$p kaldırılamadı."
        return 1
    fi
}

pip_listele() {
    local pip_cmd
    pip_cmd=$(_pip_cmd)
    [ -z "$pip_cmd" ] && { _hata "pip yüklü değil! Kurmak için: pkg install python"; return 1; }
    _bilgi "Python paketleri listeleniyor..."
    $pip_cmd list 2>/dev/null | tail -n +3 | while read -r paket versiyon rest; do
        [ -n "$paket" ] && printf "  ${BEYAZ}%-30s${NC} %s\n" "$paket" "$versiyon"
    done | less -R
    _log "BILGI" "pip listesi görüntülendi"
}

pip_kur() {
    local pip_cmd p
    pip_cmd=$(_pip_cmd)
    [ -z "$pip_cmd" ] && { _hata "pip yok! pkg install python"; return 1; }
    [ -z "$1" ] && { echo -n -e "${YESIL}pip paketi: ${NC}"; read -r p < /dev/tty; } || p="$1"
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _bilgi "Yükleniyor: $p"
    if $pip_cmd install --user "$p" 2>&1; then
        _basari "$p yüklendi."
    else
        _hata "Yükleme başarısız."
        return 1
    fi
}

pip_kaldir() {
    local pip_cmd p
    pip_cmd=$(_pip_cmd)
    [ -z "$pip_cmd" ] && { _hata "pip yok!"; return 1; }
    [ -z "$1" ] && { echo -n -e "${YESIL}Kaldırılacak pip paketi: ${NC}"; read -r p < /dev/tty; } || p="$1"
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _onay "'$p' kaldırılsın mı?" || return 0
    if $pip_cmd uninstall -y "$p" 2>&1; then
        _basari "$p kaldırıldı."
    else
        _hata "Kaldırma başarısız."
        return 1
    fi
}

pip_guncelle() {
    local pip_cmd p
    pip_cmd=$(_pip_cmd)
    [ -z "$pip_cmd" ] && { _hata "pip yok!"; return 1; }
    p="$1"
    if [ -z "$p" ]; then
        _bilgi "Tüm pip paketleri güncelleniyor..."
        $pip_cmd list --outdated --format=freeze 2>/dev/null \
            | cut -d= -f1 | xargs -r $pip_cmd install -U --user 2>&1
        _basari "Güncelleme tamamlandı."
    else
        _bilgi "Güncelleniyor: $p"
        $pip_cmd install -U --user "$p" 2>&1 \
            && _basari "$p güncellendi." || _hata "Başarısız."
    fi
}

pip_onbellek_temizle() {
    local pip_cmd
    pip_cmd=$(_pip_cmd)
    [ -z "$pip_cmd" ] && { _hata "pip yok!"; return 1; }
    $pip_cmd cache purge 2>/dev/null \
        && _basari "Pip önbelleği temizlendi." \
        || _bilgi "Önbellek zaten temiz."
}

npm_listele() {
    command -v npm &>/dev/null || { _hata "npm yok! pkg install nodejs"; return 1; }
    _bilgi "Node.js global paketleri:"
    npm list -g --depth=0 2>/dev/null | tail -n +2 | less -R
}

npm_kur() {
    command -v npm &>/dev/null || { _hata "npm yok! pkg install nodejs"; return 1; }
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}npm paketi: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _bilgi "Yükleniyor: $p"
    npm install -g "$p" 2>&1 && _basari "$p yüklendi." || _hata "Başarısız."
}

npm_kaldir() {
    command -v npm &>/dev/null || { _hata "npm yok!"; return 1; }
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Kaldırılacak npm paketi: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _onay "'$p' kaldırılsın mı?" || return 0
    npm uninstall -g "$p" 2>&1 && _basari "$p kaldırıldı." || _hata "Başarısız."
}

npm_onbellek_temizle() {
    command -v npm &>/dev/null || { _hata "npm yok!"; return 1; }
    npm cache clean --force 2>/dev/null && _basari "npm önbelleği temizlendi." || _hata "Temizlenemedi."
}

paket_yedekle() {
    local dosya="$YEDEK_KOKU/paketler_$(date +%Y%m%d_%H%M%S).txt"
    pkg list-installed 2>/dev/null | awk '{print $1}' | sort > "$dosya"
    local s
    s=$(wc -l < "$dosya")
    ln -sf "$dosya" "$YEDEK_KOKU/son_paketler.txt" 2>/dev/null
    _basari "$s paket yedeklendi: $dosya"
    _bilgi "Geri yüklemek için: $0 paket-geri"
    _log "BILGI" "Paket yedeği: $dosya"
}

paket_geri_yukle() {
    local dosya="$1"
    if [ -z "$dosya" ]; then
        _bilgi "Mevcut paket yedekleri:"
        ls -1 "$YEDEK_KOKU"/paketler_*.txt 2>/dev/null | cat -n
        if [ $? -ne 0 ]; then
            _hata "Yedek bulunamadı!"
            return 1
        fi
        echo ""
        echo -n -e "${YESIL}Yüklenecek yedek numarası: ${NC}"
        read -r num < /dev/tty
        dosya=$(ls -1 "$YEDEK_KOKU"/paketler_*.txt 2>/dev/null | sed -n "${num}p")
    fi
    [ ! -f "$dosya" ] && { _hata "Yedek bulunamadı: $dosya"; return 1; }
    _onay "Paketler geri yüklensin mi?" || return 0
    _bilgi "Geri yükleniyor: $dosya"
    local basarili=0 basarisiz=0
    while read -r p; do
        [ -n "$p" ] || continue
        echo -n "  Kuruluyor: $p ... "
        if pkg install -y "$p" &>/dev/null; then
            echo -e "${YESIL}OK${NC}"
            ((basarili++))
        else
            echo -e "${KIRMIZI}HATA${NC}"
            ((basarisiz++))
        fi
    done < "$dosya"
    _basari "Tamamlandı: $basarili başarılı, $basarisiz başarısız"
    _log "BILGI" "Paket geri yükleme: $basarili OK, $basarisiz HATA"
}

paket_onbellek_temizle() {
    local once sonra kazanc
    once=$(df "$PREFIX" 2>/dev/null | tail -1 | awk '{print $3}' || echo 0)
    pkg clean &>/dev/null
    apt clean &>/dev/null
    sonra=$(df "$PREFIX" 2>/dev/null | tail -1 | awk '{print $3}' || echo 0)
    kazanc=$((once - sonra))
    [ "$kazanc" -lt 0 ] && kazanc=0
    _basari "Paket önbelleği temizlendi. (~${kazanc}KB kazanıldı)"
    _log "BILGI" "Paket önbelleği temizlendi"
}

paket_listesi_kaydet() {
    local dosya="$HOME/paket_listesi_$(date +%Y%m%d_%H%M%S).txt"
    pkg list-installed 2>/dev/null > "$dosya"
    _basari "Kaydedildi: $dosya"
}

modul_paket() {
    while true; do
        _baslik "$MAVI" "📦 PAKET YÖNETİMİ (18 FONKSİYON)"
        echo -e "  ${BEYAZ}[1]${NC}  Yüklü paketleri listele"
        echo -e "  ${BEYAZ}[2]${NC}  Paket sayısı"
        echo -e "  ${BEYAZ}[3]${NC}  Güncellenebilir paketler"
        echo -e "  ${BEYAZ}[4]${NC}  Tek paket güncelle"
        echo -e "  ${BEYAZ}[5]${NC}  Tüm paketleri güncelle"
        echo -e "  ${BEYAZ}[6]${NC}  Paket ara"
        echo -e "  ${BEYAZ}[7]${NC}  Paket yükle"
        echo -e "  ${BEYAZ}[8]${NC}  Paket kaldır"
        echo -e "  ${BEYAZ}[9]${NC}  🐍 Python (pip) yönetimi"
        echo -e "  ${BEYAZ}[10]${NC} 🟢 Node.js (npm) yönetimi"
        echo -e "  ${BEYAZ}[11]${NC} Paket listesini yedekle"
        echo -e "  ${BEYAZ}[12]${NC} Yedeği geri yükle"
        echo -e "  ${BEYAZ}[13]${NC} Paket önbelleği temizle"
        echo -e "  ${BEYAZ}[14]${NC} Listeyi dosyaya kaydet"
        echo -e "  ${BEYAZ}[15]${NC} ⚙️  Gelişmiş paket işlemleri"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-15]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1) _baslik "$MAVI" "YÜKLÜ PAKETLER"; paket_listele ;;
            2) _baslik "$MAVI" "PAKET SAYISI"; paket_sayisi; _bekle ;;
            3) _baslik "$MAVI" "GÜNCELLEMELER"; paket_guncelle_kontrol; _bekle ;;
            4) _baslik "$MAVI" "TEK PAKET GÜNCELLE"; paket_guncelle_tek; _bekle ;;
            5) _baslik "$MAVI" "TÜMÜNÜ GÜNCELLE"
               _onay "Tüm paketler güncellensin mi?" && paket_guncelle_tumu; _bekle ;;
            6) _baslik "$MAVI" "PAKET ARA"; paket_ara; _bekle ;;
            7) _baslik "$MAVI" "PAKET YÜKLE"; paket_kur; _bekle ;;
            8) _baslik "$MAVI" "PAKET KALDIR"; paket_kaldir; _bekle ;;
            9)
                while true; do
                    _baslik "$MAVI" "🐍 PIP YÖNETİMİ"
                    echo -e "  ${BEYAZ}[1]${NC} Listele"
                    echo -e "  ${BEYAZ}[2]${NC} Yükle"
                    echo -e "  ${BEYAZ}[3]${NC} Kaldır"
                    echo -e "  ${BEYAZ}[4]${NC} Güncelle (tek veya tümü)"
                    echo -e "  ${BEYAZ}[5]${NC} Önbellek temizle"
                    echo -e "  ${BEYAZ}[0]${NC} Geri"
                    echo -n -e "${YESIL}Seçim: ${NC}"; read -r ps < /dev/tty
                    case $ps in
                        1) pip_listele ;;
                        2) pip_kur; _bekle ;;
                        3) pip_kaldir; _bekle ;;
                        4)
                            echo -n -e "${YESIL}Paket adı (boş=tümü): ${NC}"
                            read -r pp < /dev/tty
                            pip_guncelle "$pp"; _bekle ;;
                        5) pip_onbellek_temizle; _bekle ;;
                        0) break ;;
                        *) _hata "Geçersiz!"; sleep 1 ;;
                    esac
                done ;;
            10)
                while true; do
                    _baslik "$MAVI" "🟢 NPM YÖNETİMİ"
                    echo -e "  ${BEYAZ}[1]${NC} Listele"
                    echo -e "  ${BEYAZ}[2]${NC} Yükle"
                    echo -e "  ${BEYAZ}[3]${NC} Kaldır"
                    echo -e "  ${BEYAZ}[4]${NC} Önbellek temizle"
                    echo -e "  ${BEYAZ}[0]${NC} Geri"
                    echo -n -e "${YESIL}Seçim: ${NC}"; read -r ns < /dev/tty
                    case $ns in
                        1) npm_listele; _bekle ;;
                        2) npm_kur; _bekle ;;
                        3) npm_kaldir; _bekle ;;
                        4) npm_onbellek_temizle; _bekle ;;
                        0) break ;;
                        *) _hata "Geçersiz!"; sleep 1 ;;
                    esac
                done ;;
            11) _baslik "$MAVI" "PAKET YEDEKLE"; paket_yedekle; _bekle ;;
            12) _baslik "$MAVI" "GERİ YÜKLE"; paket_geri_yukle; _bekle ;;
            13) _baslik "$MAVI" "ÖNBELLEK TEMİZLE"; paket_onbellek_temizle; _bekle ;;
            14) _baslik "$MAVI" "LİSTEYİ KAYDET"; paket_listesi_kaydet; _bekle ;;
            15) modul_paket_ek ;;
            0) return 0 ;;
            *) _hata "Geçersiz seçim!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 2 — DOSYA/KLASÖR YÖNETİMİ (16 FONKSİYON)
# ============================================================

dizin_listele() {
    local d
    d=$(_path_genislet "${1:-$HOME}")
    _bilgi "Dizin: $d"
    ls -lah --color=always "$d" 2>/dev/null | less -R
    _log "BILGI" "Dizin listelendi: $d"
}

disk_kullanimi() {
    _bilgi "Disk Kullanımı:"
    echo -e "${BEYAZ}Termux ile ilgili alanlar:${NC}"
    df -h 2>/dev/null | grep -E "(/data|/sdcard|Filesystem)" || df -h 2>/dev/null | head -5
    echo ""
    echo -e "${BEYAZ}Tüm bölümler:${NC}"
    df -h 2>/dev/null | less -R
    _log "BILGI" "Disk kullanımı görüntülendi"
}

dizin_boyutlari() {
    local d
    d=$(_path_genislet "${1:-$HOME}")
    _bilgi "Dizin boyutları: $d"
    du -sh "$d"/* 2>/dev/null | sort -hr | head -30 | while read -r b dd; do
        printf "  ${BEYAZ}%-10s${NC} %s\n" "$b" "$dd"
    done | less -R
}

en_buyuk_dosyalar() {
    local limit="${1:-20}"
    _bilgi "En büyük $limit dosya aranıyor..."
    find "$HOME" -type f -exec du -b {} + 2>/dev/null \
        | sort -nr | head -n "$limit" \
        | while read -r boyut dosya; do
            local h
            h=$(numfmt --to=iec "$boyut" 2>/dev/null || echo "${boyut}B")
            printf "  ${BEYAZ}%-8s${NC} %s\n" "$h" "$dosya"
        done | less -R
    _log "BILGI" "Büyük dosyalar tarandı"
}

dosya_turu_analiz() {
    _bilgi "Dosya türü analizi yapılıyor..."
    find "$HOME" -type f 2>/dev/null | while read -r f; do
        echo "${f##*.}"
    done | sort | uniq -c | sort -nr | head -20 \
    | while read -r sayi uzanti; do
        [ -n "$uzanti" ] && printf "  ${BEYAZ}%5d${NC} dosya  .%s\n" "$sayi" "$uzanti"
    done | less -R
    _log "BILGI" "Dosya türü analizi tamamlandı"
}

depolama_durumu() {
    echo -e "${BEYAZ}=== Android Depolama ===${NC}"
    if [ -d /sdcard ]; then
        df -h /sdcard 2>/dev/null | tail -1 || echo "  Erişilemiyor"
    else
        echo "  /sdcard erişilemiyor — termux-setup-storage çalıştırın"
    fi
    echo ""
    echo -e "${BEYAZ}=== Termux Home ===${NC}"
    df -h "$HOME" 2>/dev/null | tail -1
    echo ""
    echo -e "${BEYAZ}=== Bağlı Alanlar ===${NC}"
    if [ -d ~/storage ]; then
        for d in shared downloads dcim camera pictures music movies; do
            if [ -d ~/storage/$d ]; then
                local bos
                bos=$(df -h ~/storage/$d 2>/dev/null | tail -1 | awk '{print $4}')
                printf "  ${BEYAZ}%-12s${NC} %s boş\n" "$d" "$bos"
            fi
        done
    else
        _bilgi "Depolama erişimi için: termux-setup-storage"
    fi
    _bekle
}

dosya_ara_isim() {
    local p="$1"
    [ -z "$p" ] && {
        echo -n -e "${YESIL}Dosya adı (* wildcard desteklenir): ${NC}"
        read -r p < /dev/tty
    }
    [ -z "$p" ] && { _hata "Arama terimi boş!"; return 1; }
    _bilgi "Aranıyor: $p"
    find ~ -name "$p" 2>/dev/null | cat -n | less -R
    _log "BILGI" "Dosya arama (isim): $p"
}

dosya_ara_icerik() {
    local m="$1" u="$2"
    [ -z "$m" ] && {
        echo -n -e "${YESIL}Aranacak metin: ${NC}"
        read -r m < /dev/tty
    }
    [ -z "$u" ] && {
        echo -n -e "${YESIL}Uzantı (örn: *.sh, boş=tümü): ${NC}"
        read -r u < /dev/tty
    }
    u="${u:-*}"
    [ -z "$m" ] && { _hata "Aranacak metin boş!"; return 1; }
    _bilgi "Arıyor: '$m' içinde $u"
    grep -rln "$m" ~ --include="$u" 2>/dev/null | while read -r f; do
        local satir
        satir=$(grep -n "$m" "$f" 2>/dev/null | head -1)
        echo -e "  ${TURKUAZ}$f${NC} → $satir"
    done | less -R
    _log "BILGI" "Dosya arama (içerik): $m"
}

dosya_kopyala() {
    echo -n -e "${YESIL}Kaynak yol: ${NC}"; read -r k < /dev/tty
    echo -n -e "${YESIL}Hedef yol: ${NC}"; read -r h < /dev/tty
    k=$(_path_genislet "$k")
    h=$(_path_genislet "$h")
    [ ! -e "$k" ] && { _hata "Kaynak bulunamadı: $k"; return 1; }
    cp -r "$k" "$h" 2>&1 && _basari "Kopyalandı: $k → $h" || _hata "Kopyalama başarısız."
}

dosya_tasi() {
    echo -n -e "${YESIL}Kaynak yol: ${NC}"; read -r k < /dev/tty
    echo -n -e "${YESIL}Hedef yol: ${NC}"; read -r h < /dev/tty
    k=$(_path_genislet "$k")
    h=$(_path_genislet "$h")
    [ ! -e "$k" ] && { _hata "Kaynak bulunamadı: $k"; return 1; }
    mv "$k" "$h" 2>&1 && _basari "Taşındı: $k → $h" || _hata "Taşıma başarısız."
}

dosya_sil() {
    echo -n -e "${YESIL}Silinecek yol: ${NC}"; read -r y < /dev/tty
    y=$(_path_genislet "$y")
    [ ! -e "$y" ] && { _hata "Bulunamadı: $y"; return 1; }
    ls -ld "$y"
    _onay "'$y' silinsin mi? ${KIRMIZI}(GERİ ALINAMAZ!)${NC}" || return 0
    rm -rf "$y" 2>&1 && _basari "Silindi: $y" || _hata "Silinemedi."
}

klasor_olustur() {
    echo -n -e "${YESIL}Klasör yolu: ${NC}"; read -r y < /dev/tty
    y=$(_path_genislet "$y")
    mkdir -p "$y" 2>&1 && _basari "Oluşturuldu: $y" || _hata "Oluşturma başarısız."
}

son_degisenler() {
    local limit="${1:-20}"
    _bilgi "Son $limit değiştirilen dosya:"
    find "$HOME" -type f -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr | head -n "$limit" \
        | cut -d' ' -f2- | cat -n | less -R
}

izin_duzelt() {
    echo -n -e "${YESIL}Dosya/klasör: ${NC}"; read -r y < /dev/tty
    echo -n -e "${YESIL}İzin (örn: 755, 644): ${NC}"; read -r i < /dev/tty
    y=$(_path_genislet "$y")
    [ ! -e "$y" ] && { _hata "Bulunamadı: $y"; return 1; }
    chmod -R "$i" "$y" 2>&1 && _basari "İzinler değiştirildi: $i → $y" || _hata "Başarısız."
}

dosya_bilgi() {
    local f="$1"
    [ -z "$f" ] && {
        echo -n -e "${YESIL}Dosya yolu: ${NC}"
        read -r f < /dev/tty
    }
    f=$(_path_genislet "$f")
    [ ! -f "$f" ] && { _hata "Dosya yok: $f"; return 1; }
    _baslik "$TURKUAZ" "DOSYA BİLGİSİ: $(basename "$f")"
    echo -e "${BEYAZ}Yol:${NC}         $f"
    echo -e "${BEYAZ}Boyut:${NC}       $(du -h "$f" | cut -f1)"
    echo -e "${BEYAZ}Satır:${NC}       $(wc -l < "$f")"
    echo -e "${BEYAZ}İzinler:${NC}     $(ls -l "$f" | awk '{print $1}')"
    echo -e "${BEYAZ}Sahibi:${NC}      $(ls -l "$f" | awk '{print $3":"$4}')"
    echo -e "${BEYAZ}Son değişim:${NC} $(stat -c %y "$f" 2>/dev/null | cut -d. -f1)"
    echo -e "${BEYAZ}MD5:${NC}         $(md5sum "$f" 2>/dev/null | cut -d' ' -f1)"
    echo ""
    echo -e "${TURKUAZ}İlk 10 satır:${NC}"
    _ayirac
    head -10 "$f"
    _ayirac
    _bekle
}

modul_dosya() {
    while true; do
        _baslik "$YESIL" "📁 DOSYA/KLASÖR YÖNETİMİ (16 FONKSİYON)"
        echo -e "  ${BEYAZ}[1]${NC}  Home dizini içeriği"
        echo -e "  ${BEYAZ}[2]${NC}  Disk kullanımı"
        echo -e "  ${BEYAZ}[3]${NC}  Dizin boyutları (büyükten küçüğe)"
        echo -e "  ${BEYAZ}[4]${NC}  En büyük 20 dosya"
        echo -e "  ${BEYAZ}[5]${NC}  Dosya türü analizi"
        echo -e "  ${BEYAZ}[6]${NC}  Depolama durumu (Android + Termux)"
        echo -e "  ${BEYAZ}[7]${NC}  Dosya ara (isim)"
        echo -e "  ${BEYAZ}[8]${NC}  Dosya ara (içerik/grep)"
        echo -e "  ${BEYAZ}[9]${NC}  Dosya kopyala"
        echo -e "  ${BEYAZ}[10]${NC} Dosya taşı"
        echo -e "  ${BEYAZ}[11]${NC} Dosya/klasör sil"
        echo -e "  ${BEYAZ}[12]${NC} Klasör oluştur"
        echo -e "  ${BEYAZ}[13]${NC} Son değiştirilen dosyalar"
        echo -e "  ${BEYAZ}[14]${NC} İzinleri düzelt (chmod)"
        echo -e "  ${BEYAZ}[15]${NC} Dosya bilgisi (boyut, MD5, izin)"
        echo -e "  ${BEYAZ}[16]${NC} Başka dizini listele"
        echo -e "  ${BEYAZ}[17]${NC} ⚙️  Gelişmiş dosya işlemleri"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-17]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1)  _baslik "$YESIL" "HOME DİZİNİ"; dizin_listele ~ ;;
            2)  _baslik "$YESIL" "DİSK KULLANIMI"; disk_kullanimi ;;
            3)  _baslik "$YESIL" "DİZİN BOYUTLARI"; dizin_boyutlari; _bekle ;;
            4)  _baslik "$YESIL" "EN BÜYÜK DOSYALAR"; en_buyuk_dosyalar ;;
            5)  _baslik "$YESIL" "DOSYA TÜRÜ ANALİZİ"; dosya_turu_analiz ;;
            6)  _baslik "$YESIL" "DEPOLAMA DURUMU"; depolama_durumu ;;
            7)  _baslik "$YESIL" "DOSYA ARA (İSİM)"; dosya_ara_isim; _bekle ;;
            8)  _baslik "$YESIL" "DOSYA ARA (İÇERİK)"; dosya_ara_icerik; _bekle ;;
            9)  _baslik "$YESIL" "DOSYA KOPYALA"; dosya_kopyala; _bekle ;;
            10) _baslik "$YESIL" "DOSYA TAŞI"; dosya_tasi; _bekle ;;
            11) _baslik "$YESIL" "SİL"; dosya_sil; _bekle ;;
            12) _baslik "$YESIL" "KLASÖR OLUŞTUR"; klasor_olustur; _bekle ;;
            13) _baslik "$YESIL" "SON DEĞİŞTİRİLEN"; son_degisenler ;;
            14) _baslik "$YESIL" "İZİN DÜZELT"; izin_duzelt; _bekle ;;
            15) _baslik "$YESIL" "DOSYA BİLGİSİ"; dosya_bilgi; _bekle ;;
            16)
                echo -n -e "${YESIL}Dizin yolu: ${NC}"
                read -r d < /dev/tty
                _baslik "$YESIL" "DİZİN: $d"
                dizin_listele "$d" ;;
            17) modul_dosya_ek ;;
            0) return 0 ;;
            *) _hata "Geçersiz seçim!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 3 — PROJE VE GIT YÖNETİMİ (17 FONKSİYON)
# ============================================================

git_projeleri_bul() {
    _bilgi "Git projeleri aranıyor..."
    > "$PROJE_LISTESI.tmp" 2>/dev/null
    find "$HOME" -name ".git" -type d 2>/dev/null | while read -r gd; do
        local pd
        pd=$(dirname "$gd")
        [ -d "$pd" ] || continue
        local branch remote degisiklik
        branch=$(git -C "$pd" branch --show-current 2>/dev/null || echo "N/A")
        remote=$(git -C "$pd" remote -v 2>/dev/null | head -1 | awk '{print $2}' || echo "")
        degisiklik=$(git -C "$pd" status -s 2>/dev/null | wc -l)
        printf "  ${TURKUAZ}%-40s${NC} ${BEYAZ}%-15s${NC} %s değişiklik\n" \
            "$(basename "$pd")" "$branch" "$degisiklik"
        echo "$pd|$branch|$remote" >> "$PROJE_LISTESI.tmp"
    done
    sort -u "$PROJE_LISTESI.tmp" > "$PROJE_LISTESI" 2>/dev/null
    rm -f "$PROJE_LISTESI.tmp"
    _bekle
}

node_projeleri_bul() {
    _bilgi "Node.js projeleri aranıyor..."
    find "$HOME" -name "package.json" -type f 2>/dev/null | grep -v node_modules \
    | while read -r pj; do
        local pd nm=0
        pd=$(dirname "$pj")
        [ -d "$pd/node_modules" ] && nm=$(ls -1 "$pd/node_modules" 2>/dev/null | wc -l)
        printf "  ${BEYAZ}%-45s${NC} node_modules: %d\n" "$pd" "$nm"
    done | less -R
}

python_projeleri_bul() {
    _bilgi "Python projeleri aranıyor..."
    find "$HOME" \( -name "requirements.txt" -o -name "setup.py" \
         -o -name "Pipfile" -o -name "pyproject.toml" \) \
         -type f 2>/dev/null | while read -r f; do
        local pd env="sanal ortam yok"
        pd=$(dirname "$f")
        { [ -d "$pd/venv" ] || [ -d "$pd/.venv" ]; } && env="${YESIL}sanal ortam VAR${NC}"
        printf "  ${BEYAZ}%-45s${NC} %-16s [%s]\n" "$pd" "$(basename "$f")" "$env"
    done | less -R
}

proje_durum() {
    local pd="$1"
    [ -z "$pd" ] && {
        echo -n -e "${YESIL}Proje dizini: ${NC}"
        read -r pd < /dev/tty
    }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd" ] && { _hata "Dizin bulunamadı: $pd"; return 1; }
    _baslik "$MOR" "PROJE DURUMU: $pd"
    if [ -d "$pd/.git" ]; then
        echo -e "\n${BEYAZ}Git:${NC}"
        git -C "$pd" status -s 2>/dev/null || echo "  (temiz)"
        echo -e "  Son commit: $(git -C "$pd" log -1 --oneline 2>/dev/null || echo 'N/A')"
        echo -e "  Branch: $(git -C "$pd" branch --show-current 2>/dev/null || echo 'N/A')"
        echo -e "  Remote: $(git -C "$pd" remote -v 2>/dev/null | head -1 | awk '{print $2}' || echo 'yok')"
    else
        _bilgi "Git projesi değil."
    fi
    [ -f "$pd/package.json" ] && {
        echo -e "\n${BEYAZ}Node.js:${NC}"
        local nm=0
        [ -d "$pd/node_modules" ] && nm=$(ls -1 "$pd/node_modules" 2>/dev/null | wc -l)
        echo "  node_modules: $nm paket"
    }
    [ -f "$pd/requirements.txt" ] && {
        echo -e "\n${BEYAZ}Python:${NC}"
        echo "  requirements.txt: $(wc -l < "$pd/requirements.txt") satır"
        { [ -d "$pd/venv" ] || [ -d "$pd/.venv" ]; } && echo -e "  Sanal ortam: ${YESIL}mevcut${NC}"
    }
    _bekle
}

proje_yedekle() {
    local pd="$1"
    [ -z "$pd" ] && {
        echo -n -e "${YESIL}Proje dizini: ${NC}"
        read -r pd < /dev/tty
    }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd" ] && { _hata "Dizin bulunamadı: $pd"; return 1; }
    local ad dosya
    ad=$(basename "$pd")
    dosya="$YEDEK_KOKU/${ad}_$(date +%Y%m%d_%H%M%S).tar.gz"
    _bilgi "Yedekleniyor: $ad"
    tar -czf "$dosya" \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.venv' \
        --exclude='venv' \
        --exclude='.cache' \
        -C "$(dirname "$pd")" "$ad" 2>/dev/null
    if [ -f "$dosya" ]; then
        _basari "Yedeklendi: $dosya ($(du -h "$dosya" | cut -f1))"
    else
        _hata "Yedekleme başarısız."
        return 1
    fi
    _log "BILGI" "Proje yedeği: $dosya"
}

git_pull_proje() {
    _bilgi "Git projeleri listeleniyor..."
    mapfile -t projeler < <(find ~ -name ".git" -type d -prune 2>/dev/null | sed 's/\/.git$//')
    [ ${#projeler[@]} -eq 0 ] && { _bilgi "Git projesi bulunamadı."; _bekle; return 0; }
    local i=1
    for p in "${projeler[@]}"; do
        printf "  ${BEYAZ}%2d.${NC}  %s\n" "$i" "$p"
        ((i++))
    done
    echo ""
    echo -n -e "${YESIL}Proje numarası (0=hepsi): ${NC}"
    read -r no < /dev/tty
    if [ "$no" = "0" ]; then
        for p in "${projeler[@]}"; do
            echo -e "\n${SARI}Pull: $p${NC}"
            git -C "$p" pull 2>&1 || _hata "$p başarısız"
        done
    else
        local p="${projeler[$((no-1))]}"
        [ -d "$p" ] && git -C "$p" pull 2>&1 || _hata "Geçersiz seçim."
    fi
    _bekle
}

git_commit() {
    local pd="$1"
    [ -z "$pd" ] && {
        echo -n -e "${YESIL}Proje dizini: ${NC}"
        read -r pd < /dev/tty
    }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    cd "$pd" || return 1
    git status -s
    echo ""
    echo -n -e "${YESIL}Commit mesajı: ${NC}"
    read -r msg < /dev/tty
    [ -z "$msg" ] && { _hata "Commit mesajı boş olamaz!"; return 1; }
    git add . && git commit -m "$msg" 2>&1 && _basari "Commit yapıldı." || _hata "Commit başarısız."
    cd - &>/dev/null
}

git_push_sadece() {
    local pd="$1"
    [ -z "$pd" ] && {
        echo -n -e "${YESIL}Proje dizini: ${NC}"
        read -r pd < /dev/tty
    }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    cd "$pd" || return 1
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    _onay "'$branch' branch'ine push'lansın mı?" || { cd - &>/dev/null; return 0; }
    git push origin "$branch" 2>&1 && _basari "Push başarılı." || _hata "Push başarısız."
    cd - &>/dev/null
}

git_commit_push() {
    local pd="$1"
    [ -z "$pd" ] && {
        echo -n -e "${YESIL}Proje dizini: ${NC}"
        read -r pd < /dev/tty
    }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    cd "$pd" || return 1
    git status -s
    echo ""
    echo -n -e "${YESIL}Commit mesajı: ${NC}"
    read -r msg < /dev/tty
    [ -z "$msg" ] && { _hata "Mesaj boş olamaz!"; cd - &>/dev/null; return 1; }
    if git add . && git commit -m "$msg" 2>&1 && git push 2>&1; then
        _basari "Commit + Push başarılı."
    else
        _hata "Commit + Push başarısız."
    fi
    cd - &>/dev/null
}

git_branch_yonet() {
    local pd="$1"
    [ -z "$pd" ] && {
        echo -n -e "${YESIL}Proje dizini: ${NC}"
        read -r pd < /dev/tty
    }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    cd "$pd" || return 1
    _baslik "$MOR" "BRANCH YÖNETİMİ: $pd"
    echo -e "${BEYAZ}Mevcut:${NC} $(git branch --show-current 2>/dev/null)"
    echo -e "\n${BEYAZ}Tüm branch'ler:${NC}"
    git branch -a 2>/dev/null | cat -n
    echo ""
    echo -e "  ${BEYAZ}[1]${NC} Branch değiştir"
    echo -e "  ${BEYAZ}[2]${NC} Yeni branch oluştur"
    echo -e "  ${BEYAZ}[3]${NC} Branch sil"
    echo -e "  ${BEYAZ}[0]${NC} Geri"
    echo -n -e "${YESIL}Seçim: ${NC}"
    read -r sec < /dev/tty
    case $sec in
        1)
            echo -n "Branch adı: "; read -r br < /dev/tty
            git checkout "$br" 2>&1 && _basari "Branch değiştirildi: $br" || _hata "Başarısız." ;;
        2)
            echo -n "Yeni branch adı: "; read -r br < /dev/tty
            git checkout -b "$br" 2>&1 && _basari "Oluşturuldu: $br" || _hata "Başarısız." ;;
        3)
            echo -n "Silinecek branch: "; read -r br < /dev/tty
            _onay "'$br' silinsin mi?" && git branch -d "$br" 2>&1 && _basari "Silindi." || _hata "Başarısız." ;;
        0) ;;
        *) _hata "Geçersiz!" ;;
    esac
    cd - &>/dev/null
    _bekle
}

git_init_new() {
    echo -n -e "${YESIL}Klasör yolu: ${NC}"
    read -r kl < /dev/tty
    kl=$(_path_genislet "$kl")
    mkdir -p "$kl" && git -C "$kl" init 2>&1 \
        && _basari "Repo başlatıldı: $kl" || _hata "Başarısız."
}

git_clone() {
    local url="$1" hedef="$2"
    [ -z "$url" ] && {
        echo -n -e "${YESIL}Repo URL: ${NC}"
        read -r url < /dev/tty
    }
    [ -z "$hedef" ] && {
        echo -n -e "${YESIL}Hedef klasör (boş=otomatik): ${NC}"
        read -r hedef < /dev/tty
    }
    [ -z "$url" ] && { _hata "URL boş olamaz!"; return 1; }
    if [ -n "$hedef" ]; then
        git clone "$url" "$hedef" 2>&1 && _basari "Klonlandı: $hedef" || _hata "Başarısız."
    else
        git clone "$url" 2>&1 && _basari "Klonlandı." || _hata "Başarısız."
    fi
}

proje_ara() {
    local m="$1"
    [ -z "$m" ] && {
        echo -n -e "${YESIL}Aranacak metin: ${NC}"
        read -r m < /dev/tty
    }
    [ -z "$m" ] && { _hata "Arama terimi boş!"; return 1; }
    _bilgi "Proje dosyalarında '$m' aranıyor..."
    find ~ -type f \( -name "*.js" -o -name "*.py" -o -name "*.go" \
         -o -name "*.rs" -o -name "*.java" -o -name "*.sh" \
         -o -name "*.ts" -o -name "*.php" \) 2>/dev/null \
        | xargs grep -l "$m" 2>/dev/null | cat -n | less -R
}

proje_boyutlari() {
    _bilgi "Proje boyutları hesaplanıyor..."
    find ~ -name ".git" -type d -prune 2>/dev/null | sed 's/\/.git$//' \
    | while read -r p; do
        local b
        b=$(du -sh "$p" 2>/dev/null | cut -f1)
        printf "  ${BEYAZ}%-10s${NC} %s\n" "$b" "$p"
    done | sort -h | less -R
}

_proje_sec_menu() {
    mapfile -t projeler < <(find ~ -name ".git" -type d -prune 2>/dev/null | sed 's/\/.git$//')
    if [ ${#projeler[@]} -eq 0 ]; then
        _bilgi "Git projesi bulunamadı."
        _bekle
        return 1
    fi
    for i in "${!projeler[@]}"; do
        printf "  ${BEYAZ}%2d.${NC}  %s\n" "$((i+1))" "${projeler[$i]}"
    done
    echo ""
    echo -n -e "${YESIL}Proje numarası: ${NC}"
    read -r no < /dev/tty
    echo "${projeler[$((no-1))]}"
}

modul_proje() {
    while true; do
        _baslik "$MOR" "🚀 PROJE VE GIT YÖNETİMİ (17 FONKSİYON)"
        echo -e "  ${BEYAZ}[1]${NC}  Git projelerini listele (branch + değişiklik)"
        echo -e "  ${BEYAZ}[2]${NC}  Proje durumu (git status)"
        echo -e "  ${BEYAZ}[3]${NC}  Git log (son commit'ler, grafik)"
        echo -e "  ${BEYAZ}[4]${NC}  Git pull (tek veya tüm projeler)"
        echo -e "  ${BEYAZ}[5]${NC}  Git commit + push (hızlı)"
        echo -e "  ${BEYAZ}[6]${NC}  Git branch yönetimi (değiştir/oluştur/sil)"
        echo -e "  ${BEYAZ}[7]${NC}  Yeni repo başlat (git init)"
        echo -e "  ${BEYAZ}[8]${NC}  Repo klonla (git clone)"
        echo -e "  ${BEYAZ}[9]${NC}  Node.js projelerini bul"
        echo -e "  ${BEYAZ}[10]${NC} Python projelerini bul"
        echo -e "  ${BEYAZ}[11]${NC} Proje boyutları"
        echo -e "  ${BEYAZ}[12]${NC} Proje yedekle (tar.gz)"
        echo -e "  ${BEYAZ}[13]${NC} Proje içinde ara"
        echo -e "  ${BEYAZ}[14]${NC} Git commit (sadece commit)"
        echo -e "  ${BEYAZ}[15]${NC} Git push (sadece push)"
        echo -e "  ${BEYAZ}[16]${NC} Git diff (değişiklikleri göster)"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-16]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1) _baslik "$MOR" "GİT PROJELERİ"; git_projeleri_bul ;;
            2)
                _baslik "$MOR" "PROJE SEÇ"
                local p
                p=$(_proje_sec_menu) || continue
                proje_durum "$p" ;;
            3)
                _baslik "$MOR" "PROJE SEÇ (LOG)"
                local p
                p=$(_proje_sec_menu) || continue
                git -C "$p" log --oneline --graph --color=always -20 2>/dev/null | less -R ;;
            4) _baslik "$MOR" "GİT PULL"; git_pull_proje ;;
            5)
                _baslik "$MOR" "PROJE SEÇ (COMMIT+PUSH)"
                local p
                p=$(_proje_sec_menu) || continue
                git_commit_push "$p"; _bekle ;;
            6)
                _baslik "$MOR" "PROJE SEÇ (BRANCH)"
                local p
                p=$(_proje_sec_menu) || continue
                git_branch_yonet "$p" ;;
            7) _baslik "$MOR" "YENİ REPO"; git_init_new; _bekle ;;
            8) _baslik "$MOR" "KLONLA"; git_clone; _bekle ;;
            9) _baslik "$MOR" "NODE.JS"; node_projeleri_bul ;;
            10) _baslik "$MOR" "PYTHON"; python_projeleri_bul ;;
            11) _baslik "$MOR" "BOYUTLAR"; proje_boyutlari ;;
            12) _baslik "$MOR" "YEDEKLE"; proje_yedekle; _bekle ;;
            13) _baslik "$MOR" "ARA"; proje_ara; _bekle ;;
            14)
                _baslik "$MOR" "PROJE SEÇ (COMMIT)"
                local p
                p=$(_proje_sec_menu) || continue
                git_commit "$p"; _bekle ;;
            15)
                _baslik "$MOR" "PROJE SEÇ (PUSH)"
                local p
                p=$(_proje_sec_menu) || continue
                git_push_sadece "$p"; _bekle ;;
            16)
                _baslik "$MOR" "PROJE SEÇ (DIFF)"
                local p
                p=$(_proje_sec_menu) || continue
                git -C "$p" diff --color=always 2>/dev/null | less -R ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 4 — SCRIPT VE ALIAS MERKEZİ (45+ FONKSİYON)
# ============================================================

# ── SCRIPT YÖNETİMİ ──────────────────────────────────────────

script_listele() {
    _bilgi "Tüm .sh scriptleri:"
    find ~ -maxdepth 4 -name "*.sh" -type f 2>/dev/null | sort \
    | while read -r s; do
        printf "  ${BEYAZ}%-50s${NC} %s\n" "$s" "$(du -h "$s" 2>/dev/null | cut -f1)"
    done | cat -n | less -R
}

script_olustur() {
    local ad="$1"
    [ -z "$ad" ] && { echo -n "Script adı: "; read -r ad < /dev/tty; }
    [[ "$ad" != *.sh ]] && ad="${ad}.sh"
    local yol="$HOME/$ad"
    if [ -f "$yol" ]; then
        _onay "Dosya mevcut, üzerine yazılsın mı?" || return 0
    fi
    cat > "$yol" << 'SCRIPT_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Script: 
# Yazar: 
# Tarih: 
# Açıklama: 

set -euo pipefail

# Renkler
KIRMIZI='\033[0;31m'; YESIL='\033[0;32m'; SARI='\033[1;33m'; NC='\033[0m'

# Yardımcılar
hata()  { echo -e "${KIRMIZI}[HATA] $*${NC}" >&2; exit 1; }
basari(){ echo -e "${YESIL}[OK] $*${NC}"; }
bilgi() { echo -e "${SARI}[BİLGİ] $*${NC}"; }

main() {
    bilgi "Script başlatıldı"
    # === KODUNUZ BURAYA ===

    basari "Script tamamlandı"
}

main "$@"
SCRIPT_EOF
    chmod +x "$yol" \
        && _basari "Oluşturuldu: $yol" \
        || { _hata "Oluşturma başarısız."; return 1; }
    _onay "Düzenlemek ister misiniz?" && ${EDITOR:-nano} "$yol"
}

script_ara() {
    local k="$1"
    [ -z "$k" ] && { echo -n "Aranacak kelime: "; read -r k < /dev/tty; }
    [ -z "$k" ] && { _hata "Kelime boş!"; return 1; }
    _bilgi "Scriptlerde '$k' aranıyor..."
    grep -rln "$k" ~ --include="*.sh" 2>/dev/null \
    | while read -r f; do
        local satir
        satir=$(grep -n "$k" "$f" 2>/dev/null | head -1 | cut -d: -f1)
        echo -e "  ${TURKUAZ}$f${NC} → satır $satir"
    done | less -R
}

script_bilgi() {
    local s="$1"
    [ -z "$s" ] && { echo -n "Script yolu: "; read -r s < /dev/tty; }
    s=$(_path_genislet "$s")
    [ ! -f "$s" ] && { _hata "Dosya yok: $s"; return 1; }
    _baslik "$TURKUAZ" "SCRIPT BİLGİSİ: $(basename "$s")"
    echo -e "${BEYAZ}Yol:${NC}         $s"
    echo -e "${BEYAZ}Boyut:${NC}       $(du -h "$s" | cut -f1)"
    echo -e "${BEYAZ}Satır:${NC}       $(wc -l < "$s")"
    echo -e "${BEYAZ}Fonksiyon:${NC}   $(grep -c '^[a-zA-Z_][a-zA-Z0-9_]*()' "$s" 2>/dev/null || echo 0)"
    echo -e "${BEYAZ}İzinler:${NC}     $(ls -l "$s" | awk '{print $1}')"
    echo -e "${BEYAZ}Son değişim:${NC} $(stat -c %y "$s" 2>/dev/null | cut -d. -f1)"
    echo ""
    echo -e "${TURKUAZ}İlk 10 satır:${NC}"
    _ayirac; head -10 "$s"; _ayirac
    echo -e "\n${TURKUAZ}Son 5 satır:${NC}"
    _ayirac; tail -5 "$s"; _ayirac
    _bekle
}

script_izin_ver() {
    _bilgi "Tüm scriptlere chmod +x veriliyor..."
    find ~ -maxdepth 4 -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null
    _basari "Tüm scriptler çalıştırılabilir yapıldı."
}

script_duzenle() {
    local s="$1"
    [ -z "$s" ] && { echo -n "Düzenlenecek script: "; read -r s < /dev/tty; }
    s=$(_path_genislet "$s")
    [ ! -f "$s" ] && { _hata "Dosya yok: $s"; return 1; }
    ${EDITOR:-nano} "$s" && _basari "Düzenlendi." || _hata "Düzenleme iptal."
}

script_sil() {
    local s="$1"
    [ -z "$s" ] && { echo -n "Silinecek script: "; read -r s < /dev/tty; }
    s=$(_path_genislet "$s")
    [ ! -f "$s" ] && { _hata "Dosya yok: $s"; return 1; }
    ls -l "$s"
    _onay "EMİN MİSİN? '$(basename "$s")' silinecek!" || return 0
    rm -f "$s" && _basari "Silindi: $s" || _hata "Silinemedi."
}

script_kopyala() {
    echo -n "Kaynak: "; read -r k < /dev/tty
    echo -n "Hedef:  "; read -r h < /dev/tty
    k=$(_path_genislet "$k")
    h=$(_path_genislet "$h")
    [ ! -f "$k" ] && { _hata "Kaynak yok: $k"; return 1; }
    cp "$k" "$h" && _basari "Kopyalandı: $k → $h" || _hata "Başarısız."
}

script_tasi() {
    echo -n "Kaynak: "; read -r k < /dev/tty
    echo -n "Hedef:  "; read -r h < /dev/tty
    k=$(_path_genislet "$k")
    h=$(_path_genislet "$h")
    [ ! -f "$k" ] && { _hata "Kaynak yok: $k"; return 1; }
    mv "$k" "$h" && _basari "Taşındı: $k → $h" || _hata "Başarısız."
}

script_isim_degistir() {
    echo -n "Eski ad: "; read -r e < /dev/tty
    echo -n "Yeni ad: "; read -r y < /dev/tty
    e=$(_path_genislet "$e")
    y=$(_path_genislet "$y")
    [ ! -f "$e" ] && { _hata "Dosya yok: $e"; return 1; }
    mv "$e" "$y" && _basari "Değiştirildi: $e → $y" || _hata "Başarısız."
}

_script_yonetim() {
    while true; do
        _baslik "$SARI" "📋 SCRIPT YÖNETİMİ"
        echo -e "  ${BEYAZ}[1]${NC}  Tüm scriptleri listele"
        echo -e "  ${BEYAZ}[2]${NC}  Yeni script oluştur (şablonlu)"
        echo -e "  ${BEYAZ}[3]${NC}  Script içinde ara"
        echo -e "  ${BEYAZ}[4]${NC}  Script bilgisi (boyut, fonksiyon, izin)"
        echo -e "  ${BEYAZ}[5]${NC}  Tüm scriptlere +x izni ver"
        echo -e "  ${BEYAZ}[6]${NC}  Script düzenle (editörde aç)"
        echo -e "  ${BEYAZ}[7]${NC}  Script sil"
        echo -e "  ${BEYAZ}[8]${NC}  Script kopyala"
        echo -e "  ${BEYAZ}[9]${NC}  Script taşı"
        echo -e "  ${BEYAZ}[10]${NC} Script isim değiştir"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-10]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1)  script_listele ;;
            2)  script_olustur; _bekle ;;
            3)  script_ara; _bekle ;;
            4)  script_bilgi; _bekle ;;
            5)  script_izin_ver; _bekle ;;
            6)  script_duzenle; _bekle ;;
            7)  script_sil; _bekle ;;
            8)  script_kopyala; _bekle ;;
            9)  script_tasi; _bekle ;;
            10) script_isim_degistir; _bekle ;;
            0)  return 0 ;;
            *)  _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

# ── SCRIPT ÇALIŞTIRMA ─────────────────────────────────────────

_script_calistir_detay() {
    local script="$1"
    script=$(_path_genislet "$script")
    [ ! -f "$script" ] && { _hata "Script yok: $script"; return 1; }
    _baslik "$YESIL" "🚀 ÇALIŞTIRILIYOR: $(basename "$script")"
    echo -e "${BEYAZ}Yol:${NC}     $script"
    echo -e "${BEYAZ}Boyut:${NC}   $(du -h "$script" | cut -f1)"
    echo -e "${BEYAZ}Satır:${NC}   $(wc -l < "$script")"
    echo -e "${BEYAZ}Değişim:${NC} $(stat -c %y "$script" 2>/dev/null | cut -d. -f1)"
    echo ""
    echo -e "${TURKUAZ}İlk 10 satır:${NC}"
    _ayirac; head -10 "$script"; _ayirac; echo ""
    echo -e "${BEYAZ}Çalıştırma modu:${NC}"
    echo -e "  ${BEYAZ}[1]${NC} Normal çalıştır (./script.sh)"
    echo -e "  ${BEYAZ}[2]${NC} bash ile çalıştır"
    echo -e "  ${BEYAZ}[3]${NC} sh ile çalıştır"
    echo -e "  ${BEYAZ}[4]${NC} source olarak yükle"
    echo -e "  ${BEYAZ}[5]${NC} Debug modu (bash -x)"
    echo -e "  ${BEYAZ}[6]${NC} Sözdizimi kontrolü (bash -n)"
    echo -e "  ${BEYAZ}[0]${NC} İptal"
    echo ""
    echo -n -e "${YESIL}Seçim: ${NC}"
    read -r mod < /dev/tty
    [ "$mod" = "0" ] && return 0
    _gecmise_kaydet "$script" "$mod"
    _istatistik_guncelle "$script"
    case $mod in
        1) chmod +x "$script" 2>/dev/null; "$script" ;;
        2) bash "$script" ;;
        3) sh "$script" ;;
        4) # shellcheck source=/dev/null
           source "$script" ;;
        5) bash -x "$script" ;;
        6)
            if bash -n "$script" 2>&1; then
                _basari "Sözdizimi temiz."
            else
                _hata "Sözdizimi hatası!"
            fi
            return 0 ;;
        *) _hata "Geçersiz mod!"; return 1 ;;
    esac
    local ec=$?
    echo ""
    [ $ec -eq 0 ] && _basari "Tamamlandı (çıkış: $ec)" || _hata "Hata (çıkış: $ec)"
    if _onay "Favorilere eklensin mi?"; then
        mkdir -p "$(dirname "$FAVORI_DOSYA")"
        if ! grep -qxF "$script" "$FAVORI_DOSYA" 2>/dev/null; then
            echo "$script" >> "$FAVORI_DOSYA"
            sort -u "$FAVORI_DOSYA" -o "$FAVORI_DOSYA"
            _basari "Favorilere eklendi."
        else
            _bilgi "Zaten favorilerde."
        fi
    fi
    _bekle
}

_script_calistir_menu() {
    _baslik "$YESIL" "🎯 SCRIPT ÇALIŞTIR"
    mapfile -t scriptler < <(find ~ -maxdepth 4 -name "*.sh" -type f 2>/dev/null | sort)
    [ ${#scriptler[@]} -eq 0 ] && { _bilgi "Script bulunamadı."; _bekle; return 0; }
    for i in "${!scriptler[@]}"; do
        printf "  ${BEYAZ}%3d.${NC}  %-50s %s\n" \
            "$((i+1))" "$(basename "${scriptler[$i]}")" \
            "$(du -h "${scriptler[$i]}" 2>/dev/null | cut -f1)"
    done
    echo ""
    echo -n -e "${YESIL}Numara (0=iptal): ${NC}"
    read -r no < /dev/tty
    [ "$no" = "0" ] && return 0
    _script_calistir_detay "${scriptler[$((no-1))]}"
}

_script_ara_calistir() {
    local kelime="$1"
    [ -z "$kelime" ] && {
        echo -n "Aranacak kelime: "
        read -r kelime < /dev/tty
    }
    [ -z "$kelime" ] && return 1
    _bilgi "Aranıyor: '$kelime'..."
    local tmp
    tmp=$(mktemp)
    find ~ -maxdepth 4 -name "*${kelime}*.sh" -type f 2>/dev/null >> "$tmp"
    grep -rln "$kelime" ~ --include="*.sh" 2>/dev/null >> "$tmp"
    sort -u "$tmp" -o "$tmp"
    if [ -s "$tmp" ]; then
        echo -e "${YESIL}Bulunanlar:${NC}"
        cat -n "$tmp"
        echo ""
        echo -n -e "${YESIL}Çalıştırılacak numara (0=iptal): ${NC}"
        read -r no < /dev/tty
        if [ "$no" != "0" ] && [ -n "$no" ]; then
            local s
            s=$(sed -n "${no}p" "$tmp")
            _dosya_var_mi "$s" && _script_calistir_detay "$s" || _hata "Bulunamadı."
        fi
    else
        _bilgi "Sonuç yok: '$kelime'"
    fi
    rm -f "$tmp"
    _bekle
}

_son_scriptler() {
    _baslik "$SARI" "📌 SON ÇALIŞTIRILANLAR"
    [ ! -f "$GECMIS_DOSYA" ] && { _bilgi "Henüz script çalıştırılmamış."; _bekle; return 0; }
    mapfile -t satirlar < <(tail -20 "$GECMIS_DOSYA")
    for i in "${!satirlar[@]}"; do
        local tarih script mod ikon="▶"
        tarih=$(echo "${satirlar[$i]}" | cut -d'|' -f1)
        script=$(echo "${satirlar[$i]}" | cut -d'|' -f2)
        mod=$(echo "${satirlar[$i]}"   | cut -d'|' -f3)
        case $mod in
            2) ikon="🐚" ;; 3) ikon="📜" ;; 4) ikon="📎" ;;
            5) ikon="🔍" ;; 6) ikon="✓"  ;;
        esac
        if _dosya_var_mi "$script"; then
            printf "  ${BEYAZ}%2d.${NC}  %s  ${TURKUAZ}%s${NC}  %s\n" \
                "$((i+1))" "$ikon" "$tarih" "$script"
        else
            printf "  ${BEYAZ}%2d.${NC}  %s  ${TURKUAZ}%s${NC}  ${KIRMIZI}%s [SİLİNMİŞ]${NC}\n" \
                "$((i+1))" "$ikon" "$tarih" "$script"
        fi
    done
    echo ""
    echo -n -e "${YESIL}Tekrar çalıştır (numara/0=geri): ${NC}"
    read -r no < /dev/tty
    if [ "$no" != "0" ] && [ -n "$no" ]; then
        local s
        s=$(echo "${satirlar[$((no-1))]}" | cut -d'|' -f2)
        _script_calistir_detay "$s"
    fi
}

_hizli_script_baslat() {
    _baslik "$YESIL" "🚀 HIZLI BAŞLAT"
    echo -e "${TURKUAZ}⭐ Favoriler:${NC}"
    if [ -f "$FAVORI_DOSYA" ] && [ -s "$FAVORI_DOSYA" ]; then
        local i=1
        while read -r f; do
            _dosya_var_mi "$f" && printf "  ${BEYAZ}[F%d]${NC}  %s\n" "$i" "$(basename "$f")"
            ((i++))
            [ $i -gt 5 ] && break
        done < "$FAVORI_DOSYA"
    else
        echo "     (Favori yok)"
    fi
    echo ""
    echo -e "${TURKUAZ}🔧 Hızlı Erişim:${NC}"
    local hizli=(
        "$HOME/.termux_40_menu.sh"
        "$HOME/cyber_panel.sh"
        "$HOME/termux_cyber_panel.sh"
        "$HOME/.termux_tamir.sh"
        "$HOME/.termux_yedek.sh"
        "$HOME/termux_sistem_yoneticisi.sh"
    )
    for i in "${!hizli[@]}"; do
        local s="${hizli[$i]}"
        if _dosya_var_mi "$s"; then
            printf "  ${BEYAZ}[%d]${NC}  ${YESIL}%-45s${NC} %s\n" \
                "$((i+1))" "$(basename "$s")" "$(du -h "$s" 2>/dev/null | cut -f1)"
        else
            printf "  ${BEYAZ}[%d]${NC}  ${GRI}%-45s${NC} [yok]\n" "$((i+1))" "$(basename "$s")"
        fi
    done
    echo -e "  ${BEYAZ}[7]${NC}  Özel yol gir"
    echo -e "  ${BEYAZ}[0]${NC}  Geri"
    echo ""
    echo -n -e "${YESIL}Seçim: ${NC}"
    read -r sec < /dev/tty
    case $sec in
        [Ff][0-9]*)
            local no="${sec#[Ff]}"
            local s
            s=$(sed -n "${no}p" "$FAVORI_DOSYA" 2>/dev/null)
            _dosya_var_mi "$s" && _script_calistir_detay "$s" || _hata "Bulunamadı." ;;
        [1-6])
            local s="${hizli[$((sec-1))]}"
            _dosya_var_mi "$s" && _script_calistir_detay "$s" || _hata "Script yok." ;;
        7)
            echo -n "Yol: "
            read -r ozel < /dev/tty
            ozel=$(_path_genislet "$ozel")
            _dosya_var_mi "$ozel" && _script_calistir_detay "$ozel" || _hata "Bulunamadı." ;;
        0) ;;
        *) _hata "Geçersiz!"; sleep 1 ;;
    esac
}

_favori_scriptler() {
    _baslik "$YESIL" "⭐ FAVORİLER"
    if [ ! -f "$FAVORI_DOSYA" ] || [ ! -s "$FAVORI_DOSYA" ]; then
        _bilgi "Favori yok."
        _bekle
        return 0
    fi
    mapfile -t favoriler < "$FAVORI_DOSYA"
    for i in "${!favoriler[@]}"; do
        local f="${favoriler[$i]}"
        if _dosya_var_mi "$f"; then
            printf "  ${BEYAZ}%2d.${NC}  ${YESIL}%-50s${NC}  %s\n" \
                "$((i+1))" "$f" "$(du -h "$f" 2>/dev/null | cut -f1)"
        else
            printf "  ${BEYAZ}%2d.${NC}  ${KIRMIZI}%s [SİLİNMİŞ]${NC}\n" "$((i+1))" "$f"
        fi
    done
    echo ""
    echo -e "  ${BEYAZ}[T]${NC} Geçersizleri temizle  ${BEYAZ}[0]${NC} Geri"
    echo -n -e "${YESIL}Çalıştır (numara/0): ${NC}"
    read -r no < /dev/tty
    if [[ "$no" == [Tt] ]]; then
        local tmp
        tmp=$(mktemp)
        while read -r f; do
            _dosya_var_mi "$f" && echo "$f" >> "$tmp"
        done < "$FAVORI_DOSYA"
        mv "$tmp" "$FAVORI_DOSYA"
        _basari "Temizlendi."
        _bekle
    elif [ "$no" != "0" ] && [ -n "$no" ]; then
        _script_calistir_detay "${favoriler[$((no-1))]}"
    fi
}

_script_istatistik() {
    _baslik "$SARI" "📊 SCRIPT İSTATİSTİKLERİ"
    echo -e "${BEYAZ}Genel:${NC}"
    echo "  Toplam script: $(find ~ -maxdepth 4 -name "*.sh" -type f 2>/dev/null | wc -l)"
    echo "  Favori: $(wc -l < "$FAVORI_DOSYA" 2>/dev/null || echo 0)"
    echo "  Çalıştırma: $(wc -l < "$GECMIS_DOSYA" 2>/dev/null || echo 0)"
    echo ""
    if command -v jq &>/dev/null && [ -f "$ISTATISTIK_DOSYASI" ]; then
        echo -e "${BEYAZ}En çok kullanılanlar:${NC}"
        jq -r 'to_entries | sort_by(.value) | reverse | .[] | "  \(.key): \(.value) kez"' \
            "$ISTATISTIK_DOSYASI" 2>/dev/null | head -10
    elif [ -f "${ISTATISTIK_DOSYASI}.txt" ]; then
        echo -e "${BEYAZ}En çok kullanılanlar:${NC}"
        sort "${ISTATISTIK_DOSYASI}.txt" 2>/dev/null | uniq -c | sort -nr | head -10 \
            | while read -r c n; do echo "  $n: $c kez"; done
    else
        _bilgi "İstatistik verisi yok. Script çalıştırın ve jq yükleyin: pkg install jq"
    fi
    _bekle
}

_script_yedekleme() {
    _baslik "$SARI" "💾 SCRIPT YEDEKLEME"
    local yedek="$YEDEK_KOKU/scripts_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$yedek"
    _bilgi "Kopyalanıyor..."
    find ~ -maxdepth 4 -name "*.sh" -type f 2>/dev/null \
        | while read -r s; do cp "$s" "$yedek/" 2>/dev/null && echo -n "."; done
    echo ""
    local sayi
    sayi=$(ls "$yedek" 2>/dev/null | wc -l)
    _basari "$sayi script yedeklendi: $yedek"
    [ -f "$GECMIS_DOSYA" ] && cp "$GECMIS_DOSYA" "$yedek/" && _bilgi "Geçmiş yedeklendi."
    [ -f "$FAVORI_DOSYA" ] && cp "$FAVORI_DOSYA" "$yedek/" && _bilgi "Favoriler yedeklendi."
    _bekle
}

# ── ALIAS YÖNETİMİ (15 FONKSİYON) ───────────────────────────

alias_listele() {
    _bilgi "Mevcut aliaslar:"
    alias 2>/dev/null | sort | while read -r a; do echo "  $a"; done | less -R
    if [ -f "$ALIAS_LISTESI" ]; then
        echo ""
        echo -e "${BEYAZ}Kayıtlı aliaslar:${NC}"
        cat -n "$ALIAS_LISTESI" 2>/dev/null | less -R
    fi
}

alias_ekle() {
    local ad="$1" komut="$2"
    [ -z "$ad" ]    && { echo -n "Alias adı: ";  read -r ad    < /dev/tty; }
    [ -z "$komut" ] && { echo -n "Komut:      "; read -r komut < /dev/tty; }
    [ -z "$ad" ] || [ -z "$komut" ] && { _hata "Alanlar boş olamaz!"; return 1; }
    alias "$ad=$komut" 2>&1 \
        && echo "$ad='$komut'" >> "$ALIAS_LISTESI" 2>/dev/null \
        && _basari "Geçici alias eklendi: $ad" \
        || _hata "Başarısız."
    _bilgi "Kalıcı yapmak için: alias-kalici komutunu kullanın."
}

alias_kaldir() {
    local ad="$1"
    if [ -z "$ad" ]; then
        alias 2>/dev/null | cut -d= -f1 | sed 's/alias //' | cat -n
        echo -n "Silinecek alias adı/numarası: "
        read -r ad < /dev/tty
    fi
    if [[ "$ad" =~ ^[0-9]+$ ]]; then
        ad=$(alias 2>/dev/null | cut -d= -f1 | sed 's/alias //' | sed -n "${ad}p")
    fi
    [ -n "$ad" ] && unalias "$ad" 2>/dev/null \
        && _basari "Silindi: $ad" || _hata "Silinemedi."
    # rc dosyasından da kaldır
    for rc in ~/.bashrc ~/.zshrc; do
        [ -f "$rc" ] && sed -i "/^alias $ad=/d" "$rc" 2>/dev/null
    done
    sed -i "/^$ad=/d" "$ALIAS_LISTESI" 2>/dev/null
}

alias_duzenle() {
    local ad="$1"
    if [ -z "$ad" ]; then
        alias 2>/dev/null | cut -d= -f1 | sed 's/alias //' | cat -n
        echo -n "Düzenlenecek alias adı/numarası: "
        read -r ad < /dev/tty
    fi
    if [[ "$ad" =~ ^[0-9]+$ ]]; then
        ad=$(alias 2>/dev/null | cut -d= -f1 | sed 's/alias //' | sed -n "${ad}p")
    fi
    [ -z "$ad" ] && return 1
    local mevcut
    mevcut=$(alias "$ad" 2>/dev/null | cut -d\' -f2)
    echo -e "${BEYAZ}Mevcut:${NC} $ad='$mevcut'"
    echo -n "Yeni komut: "
    read -r yeni < /dev/tty
    [ -n "$yeni" ] && unalias "$ad" 2>/dev/null \
        && alias "$ad=$yeni" \
        && _basari "Güncellendi: $ad='$yeni'" || _hata "Başarısız."
}

alias_ara() {
    local k="$1"
    [ -z "$k" ] && { echo -n "Aranacak kelime: "; read -r k < /dev/tty; }
    [ -z "$k" ] && return 1
    alias 2>/dev/null | grep -i "$k" | while read -r a; do echo "  $a"; done | less -R
}

alias_grup_olustur() {
    [ -f "$ALIAS_GRUPLAR" ] || touch "$ALIAS_GRUPLAR"
    echo -e "${BEYAZ}Alias grupları:${NC}"
    cat -n "$ALIAS_GRUPLAR" 2>/dev/null
    echo ""
    echo -n "Yeni grup adı: "; read -r grup < /dev/tty
    [ -z "$grup" ] && return 1
    echo -e "${BEYAZ}Mevcut aliaslar:${NC}"
    alias 2>/dev/null | cut -d= -f1 | sed 's/alias //' | cat -n
    echo -n "Eklenecek alias numaraları (boşluklu): "
    read -r nums < /dev/tty
    local secilen=""
    for n in $nums; do
        local a
        a=$(alias 2>/dev/null | cut -d= -f1 | sed 's/alias //' | sed -n "${n}p")
        secilen="$secilen $a"
    done
    echo "$grup: $secilen" >> "$ALIAS_GRUPLAR" \
        && _basari "Grup oluşturuldu: $grup" || _hata "Başarısız."
}

alias_yedekle() {
    local yedek="$ALIAS_YEDEK/alias_$(date +%Y%m%d_%H%M%S).txt"
    alias 2>/dev/null > "$yedek"
    local rc="${HOME}/.${SHELL##*/}rc"
    [ ! -f "$rc" ] && rc="$HOME/.bashrc"
    cp "$rc" "$ALIAS_YEDEK/rc_$(date +%Y%m%d_%H%M%S).bak" 2>/dev/null
    [ -f "$ALIAS_LISTESI" ] && cp "$ALIAS_LISTESI" "$ALIAS_YEDEK/"
    _basari "Aliaslar yedeklendi: $yedek"
}

alias_geri_yukle() {
    mapfile -t yedekler < <(ls "$ALIAS_YEDEK"/alias_*.txt 2>/dev/null)
    [ ${#yedekler[@]} -eq 0 ] && { _hata "Yedek yok!"; return 1; }
    for i in "${!yedekler[@]}"; do
        echo "  $((i+1)). $(basename "${yedekler[$i]}")"
    done
    echo -n "Yüklenecek numara: "
    read -r no < /dev/tty
    [ -n "$no" ] && source "${yedekler[$((no-1))]}" 2>/dev/null \
        && _basari "Yüklendi." || _hata "Başarısız."
}

alias_disa_aktar() {
    local disa="$HOME/alias_export_$(date +%Y%m%d_%H%M%S).sh"
    alias 2>/dev/null | sed 's/^alias //' > "$disa" \
        && _basari "Dışa aktarıldı: $disa" || _hata "Başarısız."
}

alias_kalici_yap() {
    local ad="$1"
    [ -z "$ad" ] && { echo -n "Kalıcı yapılacak alias: "; read -r ad < /dev/tty; }
    local mevcut
    mevcut=$(alias "$ad" 2>/dev/null | cut -d\' -f2)
    [ -z "$mevcut" ] && { _hata "Alias bulunamadı: $ad"; return 1; }
    local rc="${HOME}/.${SHELL##*/}rc"
    [ ! -f "$rc" ] && rc="$HOME/.bashrc"
    if ! grep -q "^alias $ad=" "$rc" 2>/dev/null; then
        echo "alias $ad='$mevcut'" >> "$rc" \
            && _basari "Kalıcı hale getirildi: $rc" || _hata "Başarısız."
    else
        _bilgi "Zaten kalıcı."
    fi
}

alias_gecici_ekle() {
    local ad="$1" komut="$2"
    [ -z "$ad" ]    && { echo -n "Alias adı: "; read -r ad    < /dev/tty; }
    [ -z "$komut" ] && { echo -n "Komut:     "; read -r komut < /dev/tty; }
    [ -z "$ad" ] || [ -z "$komut" ] && { _hata "Alanlar boş!"; return 1; }
    alias "$ad=$komut" 2>&1 && _basari "Geçici alias eklendi: $ad" || _hata "Başarısız."
}

alias_tetikleyici_olustur() {
    [ -f "$ALIAS_TETIKLEYICI" ] || touch "$ALIAS_TETIKLEYICI"
    echo -e "${BEYAZ}Tetikleyiciler:${NC}"
    cat -n "$ALIAS_TETIKLEYICI" 2>/dev/null
    echo ""
    echo -n "Tetikleyici kısaltma (örn: 'gst'): "; read -r t < /dev/tty
    echo -n "Hedef alias/komut:                  "; read -r h < /dev/tty
    [ -n "$t" ] && [ -n "$h" ] \
        && echo "$t|$h" >> "$ALIAS_TETIKLEYICI" \
        && _basari "Eklendi: $t → $h" || _hata "Başarısız."
}

alias_tum_uygula() {
    local rc="${HOME}/.${SHELL##*/}rc"
    [ ! -f "$rc" ] && rc="$HOME/.bashrc"
    # shellcheck source=/dev/null
    source "$rc" 2>/dev/null
    [ -f "$ALIAS_LISTESI" ] && source "$ALIAS_LISTESI" 2>/dev/null
    _basari "Tüm aliaslar uygulandı."
}

_alias_yonetim() {
    while true; do
        _baslik "$SARI" "🔧 ALIAS YÖNETİMİ (15 FONKSİYON)"
        echo -e "  ${BEYAZ}[1]${NC}  Tüm aliasları listele"
        echo -e "  ${BEYAZ}[2]${NC}  Yeni alias ekle (geçici)"
        echo -e "  ${BEYAZ}[3]${NC}  Alias sil"
        echo -e "  ${BEYAZ}[4]${NC}  Alias düzenle"
        echo -e "  ${BEYAZ}[5]${NC}  Alias ara"
        echo -e "  ${BEYAZ}[6]${NC}  Alias grubu oluştur"
        echo -e "  ${BEYAZ}[7]${NC}  Alias grubu uygula"
        echo -e "  ${BEYAZ}[8]${NC}  Aliasları yedekle"
        echo -e "  ${BEYAZ}[9]${NC}  Yedekten geri yükle"
        echo -e "  ${BEYAZ}[10]${NC} Dışa aktar (.sh)"
        echo -e "  ${BEYAZ}[11]${NC} Kalıcı yap (bashrc/zshrc)"
        echo -e "  ${BEYAZ}[12]${NC} Geçici alias ekle"
        echo -e "  ${BEYAZ}[13]${NC} Tetikleyici oluştur"
        echo -e "  ${BEYAZ}[14]${NC} Tümünü uygula (source)"
        echo -e "  ${BEYAZ}[15]${NC} .bashrc'den import"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-15]: ${NC}"
        read -r sec < /dev/tty
        case $sec in
            1)  alias_listele; _bekle ;;
            2)  alias_ekle; _bekle ;;
            3)  alias_kaldir; _bekle ;;
            4)  alias_duzenle; _bekle ;;
            5)  alias_ara; _bekle ;;
            6)  alias_grup_olustur; _bekle ;;
            7)  alias_grup_uygula; _bekle ;;
            8)  alias_yedekle; _bekle ;;
            9)  alias_geri_yukle; _bekle ;;
            10) alias_disa_aktar; _bekle ;;
            11) alias_kalici_yap; _bekle ;;
            12) alias_gecici_ekle; _bekle ;;
            13) alias_tetikleyici_olustur; _bekle ;;
            14) alias_tum_uygula; _bekle ;;
            15) alias_import_bashrc; _bekle ;;
            0)  return 0 ;;
            *)  _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

modul_script_merkez() {
    while true; do
        _baslik "$SARI" "⚙️  SCRIPT VE ALIAS MERKEZİ (45+ FONKSİYON)"
        local sc_say fav_say
        sc_say=$(find ~ -maxdepth 4 -name "*.sh" -type f 2>/dev/null | wc -l)
        fav_say=$(wc -l < "$FAVORI_DOSYA" 2>/dev/null || echo 0)
        echo -e "  ${GRI}Toplam script: ${BEYAZ}$sc_say${GRI}  |  Favori: ${BEYAZ}$fav_say${NC}"
        _ayirac
        echo -e "  ${BEYAZ}[1]${NC}  📋 Script Yönetimi  ${GRI}(listele/oluştur/düzenle/sil/taşı)${NC}"
        echo -e "  ${BEYAZ}[2]${NC}  🔧 Alias Yönetimi   ${GRI}(15 işlem — tam)${NC}"
        echo -e "  ${BEYAZ}[3]${NC}  🎯 Script Çalıştır  ${GRI}(6 mod)${NC}"
        echo -e "  ${BEYAZ}[4]${NC}  🔍 Script Ara & Çalıştır"
        echo -e "  ${BEYAZ}[5]${NC}  📌 Son Çalıştırılanlar"
        echo -e "  ${BEYAZ}[6]${NC}  🚀 Hızlı Başlatıcı"
        echo -e "  ${BEYAZ}[7]${NC}  ⭐ Favori Scriptler"
        echo -e "  ${BEYAZ}[8]${NC}  📊 İstatistikler"
        echo -e "  ${BEYAZ}[9]${NC}  💾 Script Yedekleme"
        echo -e "  ${BEYAZ}[10]${NC} ⚙️  Gelişmiş (kategori/şablon)"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-10]: ${NC}"
        read -r sec < /dev/tty
        case $sec in
            1) _script_yonetim ;;
            2) _alias_yonetim ;;
            3) _script_calistir_menu ;;
            4) _script_ara_calistir ;;
            5) _son_scriptler ;;
            6) _hizli_script_baslat ;;
            7) _favori_scriptler ;;
            8) _script_istatistik ;;
            9) _script_yedekleme ;;
            10) modul_script_merkez_ek ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 5 — SİSTEM BİLGİLERİ (14 FONKSİYON)
# ============================================================

sistem_genel() {
    echo -e "${BEYAZ}Hostname:${NC}   $(uname -n 2>/dev/null)"
    echo -e "${BEYAZ}Kernel:${NC}     $(uname -r 2>/dev/null)"
    echo -e "${BEYAZ}Mimari:${NC}     $(uname -m 2>/dev/null)"
    echo -e "${BEYAZ}OS:${NC}         $(uname -o 2>/dev/null)"
    echo -e "${BEYAZ}Uptime:${NC}     $(uptime -p 2>/dev/null || uptime)"
    echo -e "${BEYAZ}Yük:${NC}        $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "${BEYAZ}Shell:${NC}      $SHELL"
    echo -e "${BEYAZ}Kullanıcı:${NC}  $(whoami)"
    echo -e "${BEYAZ}Tarih:${NC}      $(date)"
    echo -e "${BEYAZ}Termux:${NC}     $PREFIX"
    _log "BILGI" "Sistem bilgisi görüntülendi"
}

bellek_durumu() {
    if [ -f /proc/meminfo ]; then
        local total avail kullanim
        total=$(grep MemTotal    /proc/meminfo | awk '{print $2}')
        avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        kullanim=$(( (total - avail) * 100 / total ))
        echo -e "${BEYAZ}Toplam RAM:${NC}     $((total/1024)) MB"
        echo -e "${BEYAZ}Kullanılabilir:${NC} $((avail/1024)) MB"
        echo -e "${BEYAZ}Kullanım:${NC}       %$kullanim"
        local bar=""
        local i
        for ((i=0; i<kullanim/5; i++)); do bar+="█"; done
        for ((i=kullanim/5; i<20; i++)); do bar+="░"; done
        if   [ $kullanim -gt 80 ]; then echo -e "  ${KIRMIZI}[$bar] %$kullanim${NC}"
        elif [ $kullanim -gt 60 ]; then echo -e "  ${SARI}[$bar] %$kullanim${NC}"
        else                             echo -e "  ${YESIL}[$bar] %$kullanim${NC}"
        fi
    else
        free -h 2>/dev/null || echo "Bellek bilgisi alınamadı."
    fi
    echo ""
    echo -e "${BEYAZ}Swap:${NC}"
    swapon --show 2>/dev/null || echo "  Swap aktif değil."
    _log "BILGI" "Bellek durumu görüntülendi"
}

cpu_bilgisi() {
    if [ -f /proc/cpuinfo ]; then
        echo -e "${BEYAZ}Model:${NC}    $(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs || echo 'N/A')"
        echo -e "${BEYAZ}Çekirdek:${NC} $(grep -c processor /proc/cpuinfo 2>/dev/null || echo 'N/A')"
        echo -e "${BEYAZ}Mimari:${NC}   $(uname -m)"
    else
        echo "CPU bilgisi alınamadı."
    fi
    echo -e "${BEYAZ}Yük:${NC}      $(cat /proc/loadavg 2>/dev/null || echo 'N/A')"
    _log "BILGI" "CPU bilgisi görüntülendi"
}

islem_listele() {
    local limit="${1:-20}"
    echo -e "${BEYAZ}En çok CPU kullanan $limit işlem:${NC}"
    ps aux 2>/dev/null | head -1
    ps aux 2>/dev/null | sort -nrk 3,3 | head -n "$limit" | tail -n +2 | less -R
    echo -e "\n${BEYAZ}En çok RAM kullanan $limit işlem:${NC}"
    ps aux 2>/dev/null | head -1
    ps aux 2>/dev/null | sort -nrk 4,4 | head -n "$limit" | tail -n +2 | less -R
    _log "BILGI" "İşlem listesi görüntülendi"
}

islem_oldur() {
    echo -n -e "${YESIL}PID: ${NC}"
    read -r pid < /dev/tty
    [ -z "$pid" ] && return 1
    _onay "PID $pid öldürülsün mü?" || return 0
    kill "$pid" 2>/dev/null \
        && _basari "Sonlandırıldı: $pid" || _hata "Başarısız."
}

android_bilgisi() {
    command -v getprop &>/dev/null || { _hata "getprop yok!"; return 1; }
    echo -e "${BEYAZ}Sürüm:${NC}       $(getprop ro.build.version.release 2>/dev/null)"
    echo -e "${BEYAZ}API:${NC}         $(getprop ro.build.version.sdk 2>/dev/null)"
    echo -e "${BEYAZ}Cihaz:${NC}       $(getprop ro.product.model 2>/dev/null)"
    echo -e "${BEYAZ}Üretici:${NC}     $(getprop ro.product.manufacturer 2>/dev/null)"
    echo -e "${BEYAZ}Marka:${NC}       $(getprop ro.product.brand 2>/dev/null)"
    echo -e "${BEYAZ}İşlemci:${NC}     $(getprop ro.product.board 2>/dev/null)"
    echo -e "${BEYAZ}Ekran:${NC}       $(getprop ro.sf.lcd_density 2>/dev/null) dpi"
    echo -e "${BEYAZ}Dil:${NC}         $(getprop persist.sys.locale 2>/dev/null)"
    echo -e "${BEYAZ}Saat Dilimi:${NC} $(getprop persist.sys.timezone 2>/dev/null)"
    echo -e "${BEYAZ}Build:${NC}       $(getprop ro.build.display.id 2>/dev/null)"
    _log "BILGI" "Android bilgisi görüntülendi"
}

ag_bilgisi() {
    echo -e "${BEYAZ}IP Adresleri:${NC}"
    if command -v ip &>/dev/null; then
        ip -4 addr show 2>/dev/null | grep inet | grep -v 127.0.0.1 | awk '{print "  "$2}'
    else
        ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print "  "$2}'
    fi
    echo ""
    echo -e "${BEYAZ}DNS Sunucuları:${NC}"
    grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print "  "$2}'
    echo ""
    echo -e "${BEYAZ}Aktif Bağlantılar (ESTABLISHED):${NC}"
    netstat -tn 2>/dev/null | grep ESTABLISHED | head -10 | sed 's/^/  /' \
        || ss -tn 2>/dev/null | grep ESTAB | head -10 | sed 's/^/  /' \
        || echo "  Bağlantı yok veya araç yüklü değil."
    _log "BILGI" "Ağ bilgisi görüntülendi"
}

sistem_loglari() {
    if [ -f "$LOG_DOSYA" ]; then
        tail -50 "$LOG_DOSYA" 2>/dev/null | less -R
    else
        _bilgi "Log dosyası henüz oluşmadı."
    fi
}

kullanici_oturumlari() {
    w 2>/dev/null || who 2>/dev/null || echo "Oturum bilgisi alınamadı."
}

donanim_bilgisi() {
    if command -v lscpu &>/dev/null; then
        lscpu 2>/dev/null | less -R
    else
        _bilgi "lscpu bulunamadı. Kurmak için: pkg install procps"
        echo ""
        echo -e "${BEYAZ}Alternatif CPU bilgisi:${NC}"
        cat /proc/cpuinfo 2>/dev/null | grep -E "processor|model name|Hardware" | head -20
    fi
}

disk_analiz() {
    echo -e "${BEYAZ}En büyük 10 dizin:${NC}"
    du -sh ~/* 2>/dev/null | sort -hr | head -10
    echo ""
    echo -e "${BEYAZ}En büyük 10 dosya:${NC}"
    find ~ -type f -exec du -h {} + 2>/dev/null | sort -hr | head -10 | less -R
}

modul_sistem() {
    while true; do
        _baslik "$TURKUAZ" "🔧 SİSTEM BİLGİLERİ (14 FONKSİYON)"
        echo -e "  ${BEYAZ}[1]${NC}  Genel sistem özeti"
        echo -e "  ${BEYAZ}[2]${NC}  Bellek (RAM + görsel bar)"
        echo -e "  ${BEYAZ}[3]${NC}  CPU bilgisi"
        echo -e "  ${BEYAZ}[4]${NC}  Disk kullanımı"
        echo -e "  ${BEYAZ}[5]${NC}  Çalışan işlemler (CPU + RAM sırası)"
        echo -e "  ${BEYAZ}[6]${NC}  İşlem öldür"
        echo -e "  ${BEYAZ}[7]${NC}  Android / cihaz bilgisi"
        echo -e "  ${BEYAZ}[8]${NC}  Ağ arayüzleri ve bağlantılar"
        echo -e "  ${BEYAZ}[9]${NC}  Termux bilgileri"
        echo -e "  ${BEYAZ}[10]${NC} Sistem logları"
        echo -e "  ${BEYAZ}[11]${NC} Kullanıcı oturumları"
        echo -e "  ${BEYAZ}[12]${NC} Donanım bilgileri (lscpu)"
        echo -e "  ${BEYAZ}[13]${NC} Disk kullanım analizi"
        echo -e "  ${BEYAZ}[14]${NC} ⚙️  Gelişmiş sistem izleme (Samsung A34 5G)"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-14]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1)  _baslik "$TURKUAZ" "SİSTEM ÖZETİ"; sistem_genel; _bekle ;;
            2)  _baslik "$TURKUAZ" "BELLEK DURUMU"; bellek_durumu; _bekle ;;
            3)  _baslik "$TURKUAZ" "CPU BİLGİSİ"; cpu_bilgisi; _bekle ;;
            4)  _baslik "$TURKUAZ" "DİSK KULLANIMI"; disk_kullanimi; _bekle ;;
            5)  _baslik "$TURKUAZ" "İŞLEMLER"; islem_listele ;;
            6)  _baslik "$TURKUAZ" "İŞLEM ÖLDÜR"; islem_listele 20; islem_oldur; _bekle ;;
            7)  _baslik "$TURKUAZ" "ANDROİD BİLGİSİ"; android_bilgisi; _bekle ;;
            8)  _baslik "$TURKUAZ" "AĞ BİLGİSİ"; ag_bilgisi; _bekle ;;
            9)
                _baslik "$TURKUAZ" "TERMUX BİLGİLERİ"
                echo -e "${BEYAZ}Prefix:${NC}      $PREFIX"
                echo -e "${BEYAZ}Home:${NC}        $HOME"
                echo -e "${BEYAZ}Shell:${NC}       $SHELL"
                echo -e "${BEYAZ}Paket sayısı:${NC} $(pkg list-installed 2>/dev/null | wc -l)"
                echo -e "${BEYAZ}PATH:${NC}"
                echo "$PATH" | tr ':' '\n' | sed 's/^/  /'
                _bekle ;;
            10) _baslik "$TURKUAZ" "SİSTEM LOGLARI"; sistem_loglari; _bekle ;;
            11) _baslik "$TURKUAZ" "KULLANICI OTURUMLARI"; kullanici_oturumlari; _bekle ;;
            12) _baslik "$TURKUAZ" "DONANIM BİLGİSİ"; donanim_bilgisi; _bekle ;;
            13) _baslik "$TURKUAZ" "DİSK ANALİZİ"; disk_analiz; _bekle ;;
            14) modul_sistem_ek ;;
            0)  return 0 ;;
            *)  _hata "Geçersiz seçim!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 6 — DETAYLI RAPOR
# ============================================================

detayli_rapor_olustur() {
    _baslik "$MAVI" "📊 DETAYLI RAPOR OLUŞTURULUYOR"
    local dosya="$YEDEK_KOKU/rapor_$(date +%Y%m%d_%H%M%S).txt"
    _bilgi "Rapor hazırlanıyor..."
    {
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║       TERMUX SİSTEM RAPORU - $(date '+%Y-%m-%d %H:%M:%S')      ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "═══ SİSTEM BİLGİSİ ═══"
        uname -a 2>/dev/null; uptime; echo ""
        echo "═══ ANDROİD BİLGİSİ ═══"
        if command -v getprop &>/dev/null; then
            echo "Android: $(getprop ro.build.version.release)"
            echo "Cihaz:   $(getprop ro.product.model)"
            echo "Üretici: $(getprop ro.product.manufacturer)"
            echo "SDK:     $(getprop ro.build.version.sdk)"
        else
            echo "(getprop yok)"
        fi
        echo ""
        echo "═══ BELLEK DURUMU ═══"; free -h 2>/dev/null; echo ""
        echo "═══ DİSK KULLANIMI ═══"; df -h 2>/dev/null; echo ""
        echo "═══ PAKET DURUMU ═══"
        echo "Yüklü: $(pkg list-installed 2>/dev/null | wc -l) paket"
        echo "Güncellenebilir:"
        pkg list-upgradable 2>/dev/null || pkg list-updatable 2>/dev/null || echo "  (yok)"
        echo ""
        echo "═══ SCRİPT DURUMU ═══"
        echo "Toplam script: $(find ~ -name "*.sh" 2>/dev/null | wc -l)"
        echo "Favori:        $(wc -l < "$FAVORI_DOSYA" 2>/dev/null || echo 0)"
        echo "Çalıştırma:    $(wc -l < "$GECMIS_DOSYA" 2>/dev/null || echo 0)"
        echo ""
        echo "═══ PROJE DURUMU ═══"
        echo "Git projesi:    $(find ~ -name ".git" -type d 2>/dev/null | wc -l)"
        echo "Node.js projesi: $(find ~ -name "package.json" -type f 2>/dev/null | grep -v node_modules | wc -l)"
        echo "Python projesi: $(find ~ -name "requirements.txt" -type f 2>/dev/null | wc -l)"
        echo ""
        echo "═══ ALIAS DURUMU ═══"
        echo "Bash alias: $(grep -c "^alias" ~/.bashrc 2>/dev/null || echo 0)"
        echo "Zsh alias:  $(grep -c "^alias" ~/.zshrc  2>/dev/null || echo 0)"
        echo ""
        echo "═══ EN BÜYÜK 10 DOSYA ═══"
        find ~ -type f -exec du -h {} + 2>/dev/null | sort -hr | head -10
        echo ""
        echo "═══ DOSYA TÜRÜ DAĞILIMI ═══"
        find ~ -type f 2>/dev/null | while read -r f; do echo "${f##*.}"; done \
            | sort | uniq -c | sort -nr | head -10
        echo ""
        echo "═══ HOME DİZİNİ ═══"; ls -lah ~/ 2>/dev/null; echo ""
        echo "════════════════════════════════════════════════════════════"
        echo "Rapor tamamlandı: $(date)"
    } > "$dosya"
    _basari "Rapor: $dosya ($(du -h "$dosya" | cut -f1))"
    if [ -d ~/storage/downloads ]; then
        cp "$dosya" ~/storage/downloads/ 2>/dev/null \
            && _bilgi "Downloads'a kopyalandı."
    fi
    _onay "Raporu görüntülemek ister misiniz?" && less "$dosya"
    _bekle
    _log "BILGI" "Rapor oluşturuldu: $dosya"
}

# ============================================================
# MODÜL 7 — YEDEKLEME (10 FONKSİYON)
# ============================================================

tam_yedek_al() {
    local dosya="$YEDEK_KOKU/sistem_$(date +%Y%m%d_%H%M%S).tar.gz"
    _bilgi "Tam sistem yedekleniyor (bu biraz zaman alabilir)..."
    tar -czf "$dosya" \
        --exclude='.cache' \
        --exclude='node_modules' \
        --exclude='.npm' \
        --exclude='.cargo' \
        --exclude='.rustup' \
        --exclude='.gradle' \
        --exclude='.m2' \
        --exclude='__pycache__' \
        "$HOME" 2>/dev/null
    if [ -f "$dosya" ]; then
        _basari "Sistem yedeği: $dosya ($(du -h "$dosya" | cut -f1))"
    else
        _hata "Yedekleme başarısız."
        return 1
    fi
    _log "BILGI" "Tam yedek: $dosya"
}

konfig_yedekle() {
    local dosya="$YEDEK_KOKU/konfig_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$dosya" \
        "$HOME/.bashrc" \
        "$HOME/.zshrc" \
        "$HOME/.profile" \
        "$HOME/.gitconfig" \
        "$HOME/.tmux.conf" \
        "$HOME/.termux" \
        "$KONFIG_DIZINI" 2>/dev/null
    if [ -f "$dosya" ]; then
        _basari "Konfig yedeği: $dosya ($(du -h "$dosya" | cut -f1))"
    else
        _hata "Yedekleme başarısız."
        return 1
    fi
    _log "BILGI" "Konfig yedeği: $dosya"
}

yedekleri_listele() {
    _bilgi "Mevcut yedekler:"
    if [ -d "$YEDEK_KOKU" ]; then
        ls -lht "$YEDEK_KOKU" 2>/dev/null | grep -v "^total" | less -R
    else
        _bilgi "Yedek dizini boş."
    fi
}

eski_yedekleri_temizle() {
    local s
    s=$(ls "$YEDEK_KOKU" 2>/dev/null | wc -l)
    echo -e "Mevcut yedek sayısı: ${BEYAZ}$s${NC}"
    _onay "Son 3 yedek dışındakiler silinsin mi?" || return 0
    ls -t "$YEDEK_KOKU" 2>/dev/null | tail -n +4 | while read -r y; do
        rm -rf "$YEDEK_KOKU/$y" && echo -e "  ${KIRMIZI}Silindi:${NC} $y"
    done
    _basari "Eski yedekler temizlendi."
    _log "BILGI" "Eski yedekler temizlendi"
}

yedegi_android_gonder() {
    [ ! -d ~/storage/downloads ] && {
        _hata "Depolama erişimi yok! termux-setup-storage çalıştırın"
        return 1
    }
    yedekleri_listele
    echo -n -e "${YESIL}Gönderilecek yedek adı: ${NC}"
    read -r ad < /dev/tty
    if [ -e "$YEDEK_KOKU/$ad" ]; then
        cp -r "$YEDEK_KOKU/$ad" ~/storage/downloads/ \
            && _basari "Gönderildi: ~/storage/downloads/$ad" || _hata "Gönderilemedi."
    else
        _hata "Bulunamadı: $ad"
    fi
}

otomatik_yedekleme() {
    _onay "Saatlik otomatik yedekleme için cron kurulsun mu?" || return 0
    if ! command -v crontab &>/dev/null; then
        _hata "cron yok! Kurmak için: pkg install cronie"
        return 1
    fi
    (crontab -l 2>/dev/null; echo "0 * * * * $0 script-yedekle >> $LOG_DOSYA 2>&1") | crontab -
    _basari "Saatlik yedekleme aktif."
    _log "BILGI" "Otomatik yedekleme kuruldu"
}

yedek_geri_yukle() {
    if [ ! -d "$YEDEK_KOKU" ] || [ -z "$(ls -A "$YEDEK_KOKU" 2>/dev/null)" ]; then
        _hata "Geri yüklenecek yedek yok."
        return 1
    fi
    _bilgi "Mevcut yedekler:"
    ls -t "$YEDEK_KOKU" | cat -n
    echo ""
    echo -n -e "${YESIL}Geri yüklenecek yedek numarası: ${NC}"
    read -r no < /dev/tty
    local ad yol
    ad=$(ls -t "$YEDEK_KOKU" | sed -n "${no}p")
    yol="$YEDEK_KOKU/$ad"
    [ ! -e "$yol" ] && { _hata "Bulunamadı."; return 1; }
    if [ -d "$yol/scripts" ]; then
        _onay "Scriptler geri yüklensin mi?" && {
            cp -r "$yol/scripts/"* ~/ 2>/dev/null
            _basari "Scriptler geri yüklendi."
        }
    fi
    if [ -f "$yol/paket_listesi.txt" ]; then
        _onay "Paket listesi geri yüklensin mi? (paketler kurulacak)" && {
            while read -r p; do
                [ -n "$p" ] && pkg install -y "$p" &>/dev/null
            done < "$yol/paket_listesi.txt"
            _basari "Paketler kuruldu."
        }
    fi
    if [ -d "$yol/config" ]; then
        _onay "Config dosyaları geri yüklensin mi?" && {
            cp -r "$yol/config/"* ~/ 2>/dev/null
            _basari "Config dosyaları geri yüklendi."
        }
    fi
    _log "BILGI" "Yedek geri yüklendi: $yol"
}

modul_yedek() {
    while true; do
        _baslik "$YESIL" "💾 YEDEKLEME (10 FONKSİYON)"
        local yedek_say yedek_boyut
        yedek_say=$(find "$YEDEK_KOKU" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l)
        yedek_boyut=$(du -sh "$YEDEK_KOKU" 2>/dev/null | cut -f1 || echo "0")
        echo -e "  ${GRI}Toplam yedek: ${BEYAZ}$yedek_say${GRI}  |  Boyut: ${BEYAZ}$yedek_boyut${NC}"
        _ayirac
        echo -e "  ${BEYAZ}[1]${NC}  Script yedekle"
        echo -e "  ${BEYAZ}[2]${NC}  Paket listesini yedekle"
        echo -e "  ${BEYAZ}[3]${NC}  Konfigürasyon dosyaları yedekle (tar.gz)"
        echo -e "  ${BEYAZ}[4]${NC}  Tam sistem yedeği (tar.gz)"
        echo -e "  ${BEYAZ}[5]${NC}  Mevcut yedekleri listele"
        echo -e "  ${BEYAZ}[6]${NC}  Eski yedekleri temizle (son 3 kalsın)"
        echo -e "  ${BEYAZ}[7]${NC}  Yedeği Android Downloads'a gönder"
        echo -e "  ${BEYAZ}[8]${NC}  Yedekten geri yükle (script+paket+config)"
        echo -e "  ${BEYAZ}[9]${NC}  Otomatik yedekleme (cron saatlik)"
        echo -e "  ${BEYAZ}[10]${NC} ⚙️  Gelişmiş yedekleme (şifreli/analiz)"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-10]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1) _script_yedekleme ;;
            2) paket_yedekle; _bekle ;;
            3) konfig_yedekle; _bekle ;;
            4) _onay "Tam sistem yedeği alınsın mı? (uzun sürebilir)" && tam_yedek_al; _bekle ;;
            5) yedekleri_listele; _bekle ;;
            6) eski_yedekleri_temizle; _bekle ;;
            7) yedegi_android_gonder; _bekle ;;
            8) yedek_geri_yukle; _bekle ;;
            9) otomatik_yedekleme; _bekle ;;
            10) modul_yedek_ek ;;
            0) return 0 ;;
            *) _hata "Geçersiz seçim!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 8 — TEMİZLİK VE OPTİMİZASYON (13 FONKSİYON)
# ============================================================

gecici_temizle() {
    [ -d "$PREFIX/tmp" ] && find "$PREFIX/tmp" -type f -atime +1 -delete 2>/dev/null
    find "$HOME" \( -name "*.tmp" -o -name "*.temp" \) -type f -atime +7 -delete 2>/dev/null
    if [ -f ~/.bash_history ]; then
        local boyut
        boyut=$(stat -c %s ~/.bash_history 2>/dev/null || echo 0)
        if [ "$boyut" -gt 10485760 ]; then
            tail -n 10000 ~/.bash_history > ~/.bash_history.tmp 2>/dev/null \
                && mv ~/.bash_history.tmp ~/.bash_history
            _bilgi "Bash history kırpıldı (10000 satıra)"
        fi
    fi
    _basari "Geçici dosyalar temizlendi."
    _log "BILGI" "Geçici dosyalar temizlendi"
}

gereksiz_bul() {
    echo -e "${BEYAZ}10MB+ log dosyaları:${NC}"
    find "$HOME" -name "*.log" -type f -size +10M 2>/dev/null \
        | while read -r f; do printf "  %-8s %s\n" "$(du -h "$f" | cut -f1)" "$f"; done
    echo ""
    echo -e "${BEYAZ}Boş dosyalar (ilk 20):${NC}"
    find "$HOME" -type f -empty 2>/dev/null | head -20 | sed 's/^/  /'
    echo ""
    echo -e "${BEYAZ}Büyük node_modules:${NC}"
    find "$HOME" -name "node_modules" -type d 2>/dev/null \
        | while read -r d; do printf "  %-8s %s\n" "$(du -sh "$d" 2>/dev/null | cut -f1)" "$d"; done | head -10
    _log "BILGI" "Gereksiz dosya taraması"
}

bos_klasor_temizle() {
    local boslar
    boslar=$(find ~ -type d -empty 2>/dev/null | grep -v "\.git")
    if [ -z "$boslar" ]; then
        _bilgi "Boş klasör bulunamadı."
        return 0
    fi
    echo -e "${BEYAZ}Boş klasörler:${NC}"
    echo "$boslar" | cat -n
    _onay "Bunlar silinsin mi?" \
        && echo "$boslar" | xargs rmdir 2>/dev/null \
        && _basari "Temizlendi." || _bilgi "İptal."
}

pycache_temizle() {
    find ~ -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    find ~ -name "*.pyc" -type f -delete 2>/dev/null
    _basari "Python cache temizlendi."
    _log "BILGI" "Python cache temizlendi"
}

node_modules_analiz() {
    echo -e "${BEYAZ}node_modules boyutları:${NC}"
    find ~ -name "node_modules" -type d -exec du -sh {} \; 2>/dev/null | sort -hr | head -20 | less -R
}

tum_temizlik() {
    _bilgi "Tüm temizlikler yapılıyor..."
    echo -n "  Paket önbelleği...  "; pkg clean &>/dev/null; apt clean &>/dev/null; echo -e "${YESIL}OK${NC}"
    echo -n "  pip önbelleği...    "
    local pip_cmd; pip_cmd=$(_pip_cmd)
    [ -n "$pip_cmd" ] && $pip_cmd cache purge &>/dev/null; echo -e "${YESIL}OK${NC}"
    echo -n "  npm önbelleği...    "
    command -v npm &>/dev/null && npm cache clean --force &>/dev/null; echo -e "${YESIL}OK${NC}"
    echo -n "  Geçici dosyalar...  "; gecici_temizle &>/dev/null; echo -e "${YESIL}OK${NC}"
    echo -n "  Python cache...     "; pycache_temizle &>/dev/null; echo -e "${YESIL}OK${NC}"
    echo -n "  Boş klasörler...    "
    find ~ -type d -empty 2>/dev/null | grep -v "\.git" | xargs rmdir 2>/dev/null; echo -e "${YESIL}OK${NC}"
    echo -n "  Log dosyası...      "; > "$LOG_DOSYA" 2>/dev/null; echo -e "${YESIL}OK${NC}"
    _basari "TÜM TEMİZLİKLER TAMAMLANDI."
    _log "BILGI" "Tam temizlik yapıldı"
}

modul_temizlik() {
    while true; do
        _baslik "$KIRMIZI" "🧹 TEMİZLİK VE OPTİMİZASYON (13 FONKSİYON)"
        local disk_yuzde
        disk_yuzde=$(df -h ~ 2>/dev/null | awk 'NR==2{print $5}')
        echo -e "  ${GRI}Disk kullanımı: ${BEYAZ}$disk_yuzde${NC}"
        _ayirac
        echo -e "  ${BEYAZ}[1]${NC}  Paket önbelleği temizle"
        echo -e "  ${BEYAZ}[2]${NC}  pip önbelleği temizle"
        echo -e "  ${BEYAZ}[3]${NC}  npm önbelleği temizle"
        echo -e "  ${BEYAZ}[4]${NC}  Geçici dosyaları temizle"
        echo -e "  ${BEYAZ}[5]${NC}  __pycache__ ve .pyc temizle"
        echo -e "  ${BEYAZ}[6]${NC}  Boş klasörleri bul ve sil"
        echo -e "  ${BEYAZ}[7]${NC}  Büyük log dosyalarını bul"
        echo -e "  ${BEYAZ}[8]${NC}  node_modules boyut analizi"
        echo -e "  ${BEYAZ}[9]${NC}  Script geçmişini temizle"
        echo -e "  ${BEYAZ}[10]${NC} Disk kullanım analizi"
        echo -e "  ${BEYAZ}[11]${NC} Sistem log dosyasını temizle"
        echo -e "  ${BEYAZ}[12]${NC} TÜM TEMİZLİKLERİ YAP"
        echo -e "  ${BEYAZ}[13]${NC} ⚙️  Gelişmiş temizlik (büyük dosya/duplicate)"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-13]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1)  paket_onbellek_temizle; _bekle ;;
            2)  pip_onbellek_temizle; _bekle ;;
            3)  npm_onbellek_temizle; _bekle ;;
            4)  gecici_temizle; _bekle ;;
            5)  pycache_temizle; _bekle ;;
            6)  bos_klasor_temizle; _bekle ;;
            7)  gereksiz_bul; _bekle ;;
            8)  node_modules_analiz; _bekle ;;
            9)
                _onay "Script geçmişi silinsin mi?" \
                    && rm -f "$GECMIS_DOSYA" && _basari "Geçmiş temizlendi."
                _bekle ;;
            10) disk_analiz; _bekle ;;
            11)
                if [ -f "$LOG_DOSYA" ]; then
                    local boyut; boyut=$(du -h "$LOG_DOSYA" | cut -f1)
                    > "$LOG_DOSYA" && _basari "Log temizlendi. ($boyut serbest)"
                else
                    _bilgi "Log dosyası mevcut değil."
                fi
                _bekle ;;
            12) _onay "TÜM temizlikler yapılsın mı?" && tum_temizlik; _bekle ;;
            13) modul_temizlik_ek ;;
            0)  return 0 ;;
            *)  _hata "Geçersiz seçim!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 9 — GÜVENLİK VE AĞ (14 FONKSİYON)
# ============================================================

acik_portlar() {
    echo -e "${BEYAZ}Açık portlar (LISTEN):${NC}"
    netstat -tuln 2>/dev/null | grep LISTEN \
        || ss -tuln 2>/dev/null | grep LISTEN \
        || _bilgi "netstat/ss yok. Kurmak için: pkg install net-tools"
    _log "BILGI" "Açık portlar sorgulandı"
}

ag_baglantilari() {
    echo -e "${BEYAZ}Bağlantılar:${NC}"
    netstat -tn 2>/dev/null | head -30 || ss -tn 2>/dev/null | head -30
}

ping_testi() {
    local adres="${1}" sayi="${2:-4}"
    [ -z "$adres" ] && {
        echo -n -e "${YESIL}Adres (IP veya domain): ${NC}"
        read -r adres < /dev/tty
    }
    [ -z "$adres" ] && { _hata "Adres boş!"; return 1; }
    _bilgi "Ping: $adres ($sayi paket)"
    ping -c "$sayi" "$adres"
    _log "BILGI" "Ping: $adres"
}

dns_sorgula() {
    local d="$1"
    [ -z "$d" ] && {
        echo -n -e "${YESIL}Domain: ${NC}"
        read -r d < /dev/tty
    }
    [ -z "$d" ] && { _hata "Domain boş!"; return 1; }
    if command -v dig &>/dev/null; then
        dig "$d"
    elif command -v nslookup &>/dev/null; then
        nslookup "$d"
    else
        getent hosts "$d" 2>/dev/null || _hata "DNS aracı yok. Kurmak için: pkg install dnsutils"
    fi
    _log "BILGI" "DNS sorgusu: $d"
}

traceroute_yap() {
    local h="$1"
    [ -z "$h" ] && {
        echo -n -e "${YESIL}Hedef adres: ${NC}"
        read -r h < /dev/tty
    }
    command -v traceroute &>/dev/null \
        && traceroute "$h" \
        || _hata "traceroute yok. Kurmak için: pkg install traceroute"
}

port_tara() {
    local hedef="$1" port="$2"
    [ -z "$hedef" ] && {
        echo -n -e "${YESIL}Hedef IP/domain: ${NC}"
        read -r hedef < /dev/tty
    }
    [ -z "$port" ] && {
        echo -n -e "${YESIL}Port/aralık (örn: 80 veya 1-1000, boş=yaygın): ${NC}"
        read -r port < /dev/tty
    }
    _log "BILGI" "Port tarama: $hedef $port"
    if [ -z "$port" ]; then
        local portlar="21 22 23 25 53 80 110 135 139 143 443 445 993 995 3306 3389 5432 6379 8080 27017"
        _bilgi "Yaygın portlar taranıyor: $hedef"
        for p in $portlar; do
            timeout 1 bash -c "echo >/dev/tcp/$hedef/$p" 2>/dev/null \
                && echo -e "  Port ${BEYAZ}$p${NC}: ${YESIL}AÇIK${NC}"
        done
    elif [[ "$port" == *"-"* ]]; then
        local bas bit
        bas=$(echo "$port" | cut -d- -f1)
        bit=$(echo "$port" | cut -d- -f2)
        _bilgi "Taranıyor: $hedef $bas-$bit"
        for ((p=bas; p<=bit; p++)); do
            timeout 1 bash -c "echo >/dev/tcp/$hedef/$p" 2>/dev/null \
                && echo -e "  Port ${BEYAZ}$p${NC}: ${YESIL}AÇIK${NC}"
        done
    else
        timeout 2 bash -c "echo >/dev/tcp/$hedef/$port" 2>/dev/null \
            && echo -e "  Port ${BEYAZ}$port${NC}: ${YESIL}AÇIK${NC}" \
            || echo -e "  Port ${BEYAZ}$port${NC}: ${KIRMIZI}KAPALI/FİLTRELİ${NC}"
    fi
    _basari "Tarama tamamlandı."
}

dis_ip() {
    _bilgi "Dış IP adresi sorgulanıyor..."
    local ip
    ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null) \
        || ip=$(curl -s --connect-timeout 5 api.ipify.org 2>/dev/null) \
        || ip=$(curl -s --connect-timeout 5 icanhazip.com 2>/dev/null)
    [ -n "$ip" ] \
        && echo -e "${BEYAZ}Dış IP:${NC} $ip" \
        || _hata "IP alınamadı. İnternet bağlantısını kontrol edin."
}

hiz_testi() {
    _bilgi "İndirme hızı test ediliyor (10MB)..."
    curl -o /dev/null -w "%{speed_download} byte/sn\n" \
        -s http://speedtest.tele2.net/10MB.zip 2>/dev/null \
        | awk '{printf "Hız: %.2f MB/sn\n", $1/1024/1024}' \
        || _hata "Test başarısız. İnternet bağlantısını kontrol edin."
}

ssh_testi() {
    echo -n -e "${YESIL}Sunucu (kullanici@adres): ${NC}"
    read -r sunucu < /dev/tty
    echo -n -e "${YESIL}Port [22]: ${NC}"
    read -r port < /dev/tty
    port="${port:-22}"
    [ -z "$sunucu" ] && { _hata "Sunucu boş!"; return 1; }
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$sunucu" exit 2>/dev/null \
        && _basari "Bağlantı başarılı." || _hata "Bağlantı başarısız."
}

web_site_kontrol() {
    echo -n -e "${YESIL}URL (https://example.com): ${NC}"
    read -r url < /dev/tty
    [ -z "$url" ] && { _hata "URL boş!"; return 1; }
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url" 2>/dev/null)
    if [ "$code" -ge 200 ] 2>/dev/null && [ "$code" -lt 300 ] 2>/dev/null; then
        _basari "Site çalışıyor (HTTP $code)"
    else
        _hata "Site erişilemiyor veya hata. HTTP Kodu: $code"
    fi
    _log "BILGI" "Web kontrol: $url ($code)"
}

ag_tara() {
    echo -n -e "${YESIL}Ağ adresi (örn: 192.168.1.0/24): ${NC}"
    read -r ag < /dev/tty
    [ -z "$ag" ] && { _hata "Ağ adresi boş!"; return 1; }
    if command -v nmap &>/dev/null; then
        nmap -sn "$ag"
    else
        _hata "nmap yok. Kurmak için: pkg install nmap"
        return 1
    fi
    _log "BILGI" "Ağ tarama: $ag"
}

ssl_kontrol() {
    echo -n -e "${YESIL}Domain (örn: google.com): ${NC}"
    read -r d < /dev/tty
    [ -z "$d" ] && { _hata "Domain boş!"; return 1; }
    if command -v openssl &>/dev/null; then
        echo | openssl s_client -connect "$d":443 -servername "$d" 2>/dev/null \
            | openssl x509 -noout -dates -subject 2>/dev/null \
            || _hata "SSL bilgisi alınamadı. Bağlantı kurulamadı."
    else
        _hata "openssl yok. Kurmak için: pkg install openssl"
        return 1
    fi
    _log "BILGI" "SSL kontrol: $d"
}

modul_guvenlik() {
    while true; do
        _baslik "$MOR" "🔍 GÜVENLİK VE AĞ (14 FONKSİYON)"
        echo -e "  ${BEYAZ}[1]${NC}  Açık portları göster"
        echo -e "  ${BEYAZ}[2]${NC}  Ağ bağlantılarını listele"
        echo -e "  ${BEYAZ}[3]${NC}  Ping testi"
        echo -e "  ${BEYAZ}[4]${NC}  DNS sorgusu"
        echo -e "  ${BEYAZ}[5]${NC}  Traceroute"
        echo -e "  ${BEYAZ}[6]${NC}  Port tarama (tek/aralık/yaygın)"
        echo -e "  ${BEYAZ}[7]${NC}  Dış IP adresi"
        echo -e "  ${BEYAZ}[8]${NC}  İndirme hız testi"
        echo -e "  ${BEYAZ}[9]${NC}  SSH bağlantı testi"
        echo -e "  ${BEYAZ}[10]${NC} Web sitesi HTTP kontrolü"
        echo -e "  ${BEYAZ}[11]${NC} Ağ cihazlarını tara (nmap)"
        echo -e "  ${BEYAZ}[12]${NC} SSL sertifika kontrolü"
        echo -e "  ${BEYAZ}[13]${NC} ⚙️  Gelişmiş güvenlik araçları"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-13]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1)  _baslik "$MOR" "AÇIK PORTLAR";      acik_portlar; _bekle ;;
            2)  _baslik "$MOR" "AĞ BAĞLANTILARI";   ag_baglantilari; _bekle ;;
            3)  _baslik "$MOR" "PİNG TESTİ";         ping_testi; _bekle ;;
            4)  _baslik "$MOR" "DNS SORGUSU";        dns_sorgula; _bekle ;;
            5)  _baslik "$MOR" "TRACEROUTE";         traceroute_yap; _bekle ;;
            6)  _baslik "$MOR" "PORT TARAMA";        port_tara; _bekle ;;
            7)  _baslik "$MOR" "DIŞ IP ADRESİ";      dis_ip; _bekle ;;
            8)  _baslik "$MOR" "HIZ TESTİ";          hiz_testi; _bekle ;;
            9)  _baslik "$MOR" "SSH TESTİ";          ssh_testi; _bekle ;;
            10) _baslik "$MOR" "WEB SİTE KONTROL";   web_site_kontrol; _bekle ;;
            11) _baslik "$MOR" "AĞ TARAMA (nmap)";   ag_tara; _bekle ;;
            12) _baslik "$MOR" "SSL SERTİFİKA";      ssl_kontrol; _bekle ;;
            13) modul_guvenlik_ek ;;
            0)  return 0 ;;
            *)  _hata "Geçersiz seçim!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 10 — ANDROİD ENTEGRASYONU (14 FONKSİYON)
# ============================================================

depolama_baglantilari() {
    echo -e "${BEYAZ}Depolama bağlantıları:${NC}"
    if [ -d ~/storage ]; then
        ls -la ~/storage/ 2>/dev/null
        echo ""
        echo -e "${BEYAZ}Alan durumu:${NC}"
        for d in shared downloads dcim camera pictures music movies; do
            if [ -d ~/storage/$d ]; then
                local bos
                bos=$(df -h ~/storage/$d 2>/dev/null | tail -1 | awk '{print $4}')
                printf "  ${BEYAZ}%-12s${NC} %s boş\n" "$d" "$bos"
            fi
        done
    else
        _hata "Depolama bağlantısı yok!"
        _bilgi "Kurmak için: termux-setup-storage"
    fi
}

pil_durumu() {
    _api_kontrol || return 1
    termux-battery-status 2>/dev/null \
        | { command -v jq &>/dev/null && jq . || cat; } \
        || _hata "Pil bilgisi alınamadı."
}

bildirim_gonder() {
    _api_kontrol || return 1
    local b="$1" ic="$2"
    [ -z "$b" ]  && { echo -n -e "${YESIL}Başlık: ${NC}";  read -r b  < /dev/tty; }
    [ -z "$ic" ] && { echo -n -e "${YESIL}İçerik: ${NC}"; read -r ic < /dev/tty; }
    termux-notification -t "$b" -c "$ic" 2>/dev/null \
        && _basari "Bildirim gönderildi." || _hata "Başarısız."
    _log "BILGI" "Bildirim: $b"
}

titresim_yap() {
    _api_kontrol || return 1
    echo -n -e "${YESIL}Süre (ms) [500]: ${NC}"
    read -r sure < /dev/tty
    sure="${sure:-500}"
    termux-vibrate -d "$sure" 2>/dev/null \
        && _basari "Titreşim: ${sure}ms" || _hata "Başarısız."
}

mesale() {
    _api_kontrol || return 1
    echo -e "  ${BEYAZ}[1]${NC} Aç   ${BEYAZ}[2]${NC} Kapat"
    echo -n -e "${YESIL}Seçim: ${NC}"
    read -r m < /dev/tty
    case $m in
        1) termux-torch -s on  2>/dev/null && _basari "Meşale açıldı."    || _hata "Başarısız." ;;
        2) termux-torch -s off 2>/dev/null && _basari "Meşale kapatıldı." || _hata "Başarısız." ;;
        *) _hata "Geçersiz seçim." ;;
    esac
}

fotograf_cek() {
    _api_kontrol || return 1
    local hedef
    if [ -d ~/storage/dcim ]; then
        hedef=~/storage/dcim/termux_$(date +%Y%m%d_%H%M%S).jpg
    else
        hedef="$HOME/fotograf_$(date +%Y%m%d_%H%M%S).jpg"
    fi
    _bilgi "Fotoğraf çekiliyor..."
    termux-camera-photo -c 0 "$hedef" 2>/dev/null
    if [ -f "$hedef" ]; then
        _basari "Kaydedildi: $hedef"
    else
        _hata "Fotoğraf çekilemedi."
        return 1
    fi
    _log "BILGI" "Fotoğraf: $hedef"
}

ses_kayit() {
    _api_kontrol || return 1
    local hedef
    if [ -d ~/storage/music ]; then
        hedef=~/storage/music/kayit_$(date +%Y%m%d_%H%M%S).m4a
    else
        hedef="$HOME/kayit_$(date +%Y%m%d_%H%M%S).m4a"
    fi
    _bilgi "Ses kaydı başlıyor. Durdurmak için Enter'a basın..."
    termux-microphone-record -d -f "$hedef" 2>/dev/null &
    local pid=$!
    read -r -s < /dev/tty
    kill $pid 2>/dev/null
    termux-microphone-record -q 2>/dev/null
    if [ -f "$hedef" ]; then
        _basari "Kaydedildi: $hedef"
    else
        _hata "Kayıt alınamadı."
        return 1
    fi
    _log "BILGI" "Ses kaydı: $hedef"
}

konum_bilgisi() {
    _api_kontrol || return 1
    _bilgi "Konum alınıyor (GPS veya ağ)..."
    termux-location -p network 2>/dev/null \
        | { command -v jq &>/dev/null && jq . || cat; } \
        || _hata "Konum alınamadı."
    _log "BILGI" "Konum alındı"
}

kisiler_listele() {
    _api_kontrol || return 1
    _bilgi "Kişiler listeleniyor..."
    termux-contact-list 2>/dev/null \
        | { command -v jq &>/dev/null && jq . || cat; } \
        | head -60
    _log "BILGI" "Kişiler listelendi"
}

sms_gonder() {
    _api_kontrol || return 1
    local numara="${1}" mesaj="${2}"
    [ -z "$numara" ] && { echo -n -e "${YESIL}Telefon numarası: ${NC}"; read -r numara < /dev/tty; }
    [ -z "$mesaj" ]  && { echo -n -e "${YESIL}Mesaj: ${NC}";            read -r mesaj  < /dev/tty; }
    [ -z "$numara" ] || [ -z "$mesaj" ] && { _hata "Numara veya mesaj boş!"; return 1; }
    _onay "$numara'ya SMS gönderilsin mi?" || return 0
    termux-sms-send -n "$numara" "$mesaj" 2>/dev/null \
        && _basari "SMS gönderildi." || _hata "Gönderilemedi."
    _log "BILGI" "SMS: $numara"
}

depolama_izni_kur() {
    _bilgi "Depolama izni isteniyor..."
    termux-setup-storage
    _basari "İşlem tamamlandı."
}

pano_islem() {
    echo -e "  ${BEYAZ}[1]${NC} Kopyala  ${BEYAZ}[2]${NC} Yapıştır"
    echo -n -e "${YESIL}Seçim: ${NC}"
    read -r p < /dev/tty
    if [ "$p" = "1" ]; then
        echo -n -e "${YESIL}Kopyalanacak metin: ${NC}"
        read -r m < /dev/tty
        echo -n "$m" | termux-clipboard-set 2>/dev/null \
            && _basari "Kopyalandı." || _hata "termux-api gerekli."
    else
        local icerik
        icerik=$(termux-clipboard-get 2>/dev/null)
        [ -n "$icerik" ] && echo "$icerik" || echo "Pano boş."
    fi
}

telefon_bilgileri() {
    echo -e "${BEYAZ}Cihaz:${NC}   $(getprop ro.product.model 2>/dev/null || echo 'N/A')"
    echo -e "${BEYAZ}Android:${NC} $(getprop ro.build.version.release 2>/dev/null || echo 'N/A')"
    echo -e "${BEYAZ}SDK:${NC}     $(getprop ro.build.version.sdk 2>/dev/null || echo 'N/A')"
    if _api_kontrol 2>/dev/null; then
        local pil
        pil=$(termux-battery-status 2>/dev/null | grep -o '"percentage":[0-9]*' | cut -d: -f2)
        [ -n "$pil" ] && echo -e "${BEYAZ}Pil:${NC}     %$pil"
    fi
}

modul_android() {
    while true; do
        _baslik "$TURKUAZ" "📱 ANDROİD ENTEGRASYONU (14 FONKSİYON)"
        echo -e "  ${BEYAZ}[1]${NC}  Depolama bağlantıları"
        echo -e "  ${BEYAZ}[2]${NC}  Pil durumu"
        echo -e "  ${BEYAZ}[3]${NC}  Bildirim gönder"
        echo -e "  ${BEYAZ}[4]${NC}  Titreşim"
        echo -e "  ${BEYAZ}[5]${NC}  Meşale (flaş)"
        echo -e "  ${BEYAZ}[6]${NC}  Kamera ile fotoğraf çek"
        echo -e "  ${BEYAZ}[7]${NC}  Ses kaydı başlat"
        echo -e "  ${BEYAZ}[8]${NC}  Konum bilgisi"
        echo -e "  ${BEYAZ}[9]${NC}  Kişileri listele"
        echo -e "  ${BEYAZ}[10]${NC} SMS gönder"
        echo -e "  ${BEYAZ}[11]${NC} Depolama izni kur"
        echo -e "  ${BEYAZ}[12]${NC} Pano (kopyala/yapıştır)"
        echo -e "  ${BEYAZ}[13]${NC} Telefon bilgileri (hızlı özet)"
        echo -e "  ${BEYAZ}[14]${NC} ⚙️  Gelişmiş Android (Samsung A34 5G)"
        echo -e "  ${BEYAZ}[0]${NC}  Ana menüye dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-14]: ${NC}"
        read -r s < /dev/tty
        case $s in
            1)  _baslik "$TURKUAZ" "DEPOLAMA";         depolama_baglantilari; _bekle ;;
            2)  _baslik "$TURKUAZ" "PİL DURUMU";       pil_durumu; _bekle ;;
            3)  _baslik "$TURKUAZ" "BİLDİRİM";         bildirim_gonder; _bekle ;;
            4)  _baslik "$TURKUAZ" "TİTREŞİM";         titresim_yap; _bekle ;;
            5)  _baslik "$TURKUAZ" "MEŞALE";            mesale; _bekle ;;
            6)  _baslik "$TURKUAZ" "FOTOĞRAF";         fotograf_cek; _bekle ;;
            7)  _baslik "$TURKUAZ" "SES KAYDI";        ses_kayit; _bekle ;;
            8)  _baslik "$TURKUAZ" "KONUM";            konum_bilgisi; _bekle ;;
            9)  _baslik "$TURKUAZ" "KİŞİLER";         kisiler_listele; _bekle ;;
            10) _baslik "$TURKUAZ" "SMS GÖNDER";       sms_gonder; _bekle ;;
            11) _baslik "$TURKUAZ" "DEPOLAMA İZNİ";    depolama_izni_kur; _bekle ;;
            12) _baslik "$TURKUAZ" "PANO";             pano_islem; _bekle ;;
            13) _baslik "$TURKUAZ" "TELEFON BİLGİSİ"; telefon_bilgileri; _bekle ;;
            14) modul_android_ek ;;
            0)  return 0 ;;
            *)  _hata "Geçersiz seçim!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# MODÜL 11 — YARDIM
# ============================================================

modul_yardim() {
    _baslik "$MAVI" "📖 YARDIM VE DOKÜMANTASYON"
    echo -e "${SARI}${BOLD}TERMUX SİSTEM YÖNETİCİSİ v5.0 — NİHAİ ULTRA SÜRÜM${NC}"
    echo -e "${GRI}Samsung Galaxy A34 5G optimizasyonlu | 53×28 terminal${NC}"
    echo ""
    echo -e "${BEYAZ}MODÜLLER (255 Fonksiyon):${NC}"
    echo "  [1]  📦 Paket      — 20+ fn  (pkg/pip/npm, yedek, bağımlılık, detay)"
    echo "  [2]  📁 Dosya      — 18+ fn  (arşiv, hash, diff, toplu adlandır)"
    echo "  [3]  🚀 Git/Proje  — 17+ fn  (commit/push/branch/stash/tag/diff)"
    echo "  [4]  ⚙️  Script/Alias — 60+ fn (kategori, şablon, 15 alias işlemi)"
    echo "  [5]  🔧 Sistem     — 21+ fn  (Galaxy A34 opt, servis, isıl, performans)"
    echo "  [6]  📊 Rapor      — detaylı sistem raporu, Android'e gönder"
    echo "  [7]  💾 Yedek      — 10+ fn  (şifreli, karşılaştır, boyut analiz)"
    echo "  [8]  🧹 Temizlik   — 13+ fn  (büyük dosya, Android cache)"
    echo "  [9]  🔍 Ağ/Güvenlik — 13+ fn (whois, HTTP başlık, şifre üret)"
    echo "  [10] 📱 Android    — 14+ fn  (pil, WiFi, video, SMS gelen, telefon)"
    echo "  [11] 📖 Yardım"
    echo ""
    echo -e "${BEYAZ}CLI ÖRNEKLER:${NC}"
    echo "  $0 paket-ara python          $0 script-calistir ~/x.sh"
    echo "  $0 ping google.com           $0 port-tara 192.168.1.1 1-100"
    echo "  $0 galaxy-opt                $0 isil-kontrol"
    echo "  $0 sifreli-yedek             $0 hash ~/dosya.sh"
    echo "  $0 whois google.com          $0 sifre-uret"
    echo "  $0 video-cek                 $0 git-stash"
    echo "  $0 yedek-boyut               $0 buyuk-dosya-sil"
    echo ""
    echo -e "${BEYAZ}KONFİG:${NC}"
    echo "  Log:        $LOG_DOSYA"
    echo "  Yedekler:   $YEDEK_KOKU"
    echo "  Konfig:     $KONFIG_DIZINI"
    echo ""
    _bekle
}

# ============================================================
# ANA MENÜ
# ============================================================

ana_menu() {
    while true; do
        clear
        echo -e "${TURKUAZ}${BOLD}"
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║   TERMUX SİSTEM YÖNETİCİSİ v4.0 — TAM SÜRÜM           ║"
        echo "║   ✅ 200+ Komut • 11 Modül • CLI + Menü • Tam Çalışır  ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        _durum_satiri
        echo ""
        echo -e "${SARI}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${SARI}║${NC}  ${BEYAZ}[1]${NC} 📦 Paket ${GRI}(18 fn)${NC}       ${BEYAZ}[2]${NC} 📁 Dosya ${GRI}(16 fn)${NC}       ${SARI}║${NC}"
        echo -e "${SARI}║${NC}  ${BEYAZ}[3]${NC} 🚀 Git/Proje ${GRI}(17 fn)${NC}   ${BEYAZ}[4]${NC} ⚙️  Script/Alias ${GRI}(45+)${NC}  ${SARI}║${NC}"
        echo -e "${SARI}║${NC}  ${BEYAZ}[5]${NC} 🔧 Sistem ${GRI}(14 fn)${NC}      ${BEYAZ}[6]${NC} 📊 Rapor                ${SARI}║${NC}"
        echo -e "${SARI}║${NC}  ${BEYAZ}[7]${NC} 💾 Yedek ${GRI}(10 fn)${NC}       ${BEYAZ}[8]${NC} 🧹 Temizlik ${GRI}(13 fn)${NC}    ${SARI}║${NC}"
        echo -e "${SARI}║${NC}  ${BEYAZ}[9]${NC} 🔍 Ağ/Güvenlik ${GRI}(14 fn)${NC} ${BEYAZ}[10]${NC} 📱 Android ${GRI}(14 fn)${NC}   ${SARI}║${NC}"
        echo -e "${SARI}║${NC}  ${BEYAZ}[11]${NC} 📖 Yardım               ${BEYAZ}[0]${NC} 🚪 Çıkış              ${SARI}║${NC}"
        echo -e "${SARI}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -n -e "${YESIL}Seçiminiz [0-11]: ${NC}"
        read -r ana_secim < /dev/tty
        case $ana_secim in
            1)  modul_paket ;;
            2)  modul_dosya ;;
            3)  modul_proje ;;
            4)  modul_script_merkez ;;
            5)  modul_sistem ;;
            6)  detayli_rapor_olustur ;;
            7)  modul_yedek ;;
            8)  modul_temizlik ;;
            9)  modul_guvenlik ;;
            10) modul_android ;;
            11) modul_yardim ;;
            0)
                echo -e "${YESIL}Çıkış yapılıyor...${NC}"
                _log "BILGI" "Program sonlandırıldı"
                exit 0 ;;
            *)
                _hata "Geçersiz! Lütfen 0-11 arası bir sayı girin."
                sleep 1 ;;
        esac
    done
}

# ============================================================
# SAMSUNG GALAXY A34 5G — EK FONKSİYONLAR VE ZENGİNLEŞTİRMELER
# ============================================================

# ─── EK PAKET FONKSİYONLARI ──────────────────────────────────

paket_bilgi() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Paket adı: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _bilgi "Paket bilgisi: $p"
    pkg show "$p" 2>/dev/null || apt show "$p" 2>/dev/null || _hata "Paket bulunamadı: $p"
    _log "BILGI" "Paket bilgisi: $p"
}

paket_bagimlilik() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Paket adı: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _bilgi "Bağımlılıklar: $p"
    apt-cache depends "$p" 2>/dev/null || _hata "apt-cache bulunamadı."
    _log "BILGI" "Paket bağımlılığı: $p"
}

paket_dosyalari() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Paket adı: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && { _hata "Paket adı boş!"; return 1; }
    _bilgi "Paket dosyaları: $p"
    dpkg -L "$p" 2>/dev/null | less -R || _hata "dpkg bulunamadı."
}

paket_hangi_pakette() {
    local dosya="$1"
    [ -z "$dosya" ] && { echo -n -e "${YESIL}Komut/dosya adı: ${NC}"; read -r dosya < /dev/tty; }
    [ -z "$dosya" ] && { _hata "Dosya adı boş!"; return 1; }
    _bilgi "Hangi pakette: $dosya"
    dpkg -S "$dosya" 2>/dev/null || command -v "$dosya" && dpkg -S "$(command -v "$dosya")" 2>/dev/null || _hata "Bulunamadı."
}

paket_istatistik() {
    echo -e "${BEYAZ}=== Paket İstatistikleri ===${NC}"
    echo -e "${BEYAZ}Yüklü paket:${NC}         $(pkg list-installed 2>/dev/null | wc -l)"
    echo -e "${BEYAZ}Güncellenebilir:${NC}     $(pkg list-upgradable 2>/dev/null | wc -l 2>/dev/null || echo '?')"
    echo -e "${BEYAZ}pkg repo boyutu:${NC}     $(du -sh "$PREFIX/var/cache/apt" 2>/dev/null | cut -f1 || echo 'N/A')"
    echo -e "${BEYAZ}Python yüklü:${NC}        $(command -v python3 &>/dev/null && python3 --version 2>/dev/null || echo 'Yüklü değil')"
    echo -e "${BEYAZ}Node.js yüklü:${NC}       $(command -v node &>/dev/null && node --version 2>/dev/null || echo 'Yüklü değil')"
    echo -e "${BEYAZ}Git yüklü:${NC}           $(command -v git &>/dev/null && git --version 2>/dev/null || echo 'Yüklü değil')"
    echo -e "${BEYAZ}jq yüklü:${NC}            $(command -v jq &>/dev/null && jq --version 2>/dev/null || echo 'Yüklü değil')"
    echo -e "${BEYAZ}termux-api yüklü:${NC}    $(command -v termux-battery-status &>/dev/null && echo 'Evet' || echo 'Hayır')"
    echo -e "${BEYAZ}nmap yüklü:${NC}          $(command -v nmap &>/dev/null && echo 'Evet' || echo 'Hayır')"
    echo -e "${BEYAZ}openssl yüklü:${NC}       $(command -v openssl &>/dev/null && echo 'Evet' || echo 'Hayır')"
    echo -e "${BEYAZ}curl yüklü:${NC}          $(command -v curl &>/dev/null && echo 'Evet' || echo 'Hayır')"
    _log "BILGI" "Paket istatistikleri görüntülendi"
}

paket_populer_kur() {
    _baslik "$MAVI" "📦 POPÜLER PAKET HIZLI KURULUM"
    echo -e "${BEYAZ}Kategori seçin:${NC}"
    echo -e "  ${BEYAZ}[1]${NC} Geliştirme  ${GRI}(git, python, nodejs, gcc, make)${NC}"
    echo -e "  ${BEYAZ}[2]${NC} Araçlar     ${GRI}(curl, wget, jq, vim, tmux, htop)${NC}"
    echo -e "  ${BEYAZ}[3]${NC} Ağ          ${GRI}(nmap, netcat, openssh, curl, wget)${NC}"
    echo -e "  ${BEYAZ}[4]${NC} Dosya       ${GRI}(zip, unzip, tar, p7zip, tree)${NC}"
    echo -e "  ${BEYAZ}[5]${NC} Medya       ${GRI}(ffmpeg, imagemagick, mpv)${NC}"
    echo -e "  ${BEYAZ}[6]${NC} API Araçları ${GRI}(termux-api, termux-services)${NC}"
    echo -e "  ${BEYAZ}[7]${NC} Güvenlik    ${GRI}(openssl, gnupg, nmap, hydra)${NC}"
    echo -e "  ${BEYAZ}[0]${NC} Geri"
    echo ""
    echo -n -e "${YESIL}Seçim: ${NC}"; read -r sec < /dev/tty
    local paketler=""
    case $sec in
        1) paketler="git python nodejs gcc make clang cmake" ;;
        2) paketler="curl wget jq vim tmux htop nano less" ;;
        3) paketler="nmap netcat-openbsd openssh curl wget dnsutils" ;;
        4) paketler="zip unzip tar p7zip tree lsd fd" ;;
        5) paketler="ffmpeg imagemagick" ;;
        6) paketler="termux-api termux-services" ;;
        7) paketler="openssl gnupg nmap" ;;
        0) return 0 ;;
        *) _hata "Geçersiz seçim!"; return 1 ;;
    esac
    echo -e "${SARI}Kurulacaklar: $paketler${NC}"
    _onay "Bu paketler kurulsun mu?" || return 0
    for p in $paketler; do
        echo -n "  Kuruluyor: $p ... "
        if pkg install -y "$p" &>/dev/null; then
            echo -e "${YESIL}OK${NC}"
        else
            echo -e "${KIRMIZI}ATLA${NC}"
        fi
    done
    _basari "Kurulum tamamlandı."
    _log "BILGI" "Toplu paket kurulumu: $paketler"
}

# ─── EK DOSYA FONKSİYONLARI ──────────────────────────────────

arsiv_olustur() {
    echo -n -e "${YESIL}Arşivlenecek dizin/dosya: ${NC}"; read -r kaynak < /dev/tty
    kaynak=$(_path_genislet "$kaynak")
    [ ! -e "$kaynak" ] && { _hata "Bulunamadı: $kaynak"; return 1; }
    echo -e "  ${BEYAZ}[1]${NC} .tar.gz  ${BEYAZ}[2]${NC} .zip  ${BEYAZ}[3]${NC} .tar.bz2  ${BEYAZ}[4]${NC} .tar.xz"
    echo -n -e "${YESIL}Format: ${NC}"; read -r fmt < /dev/tty
    local ad; ad=$(basename "$kaynak")
    local cikti
    case $fmt in
        1) cikti="${ad}_$(date +%Y%m%d).tar.gz"
           tar -czf "$cikti" -C "$(dirname "$kaynak")" "$ad" 2>&1 ;;
        2) cikti="${ad}_$(date +%Y%m%d).zip"
           zip -r "$cikti" "$kaynak" 2>&1 ;;
        3) cikti="${ad}_$(date +%Y%m%d).tar.bz2"
           tar -cjf "$cikti" -C "$(dirname "$kaynak")" "$ad" 2>&1 ;;
        4) cikti="${ad}_$(date +%Y%m%d).tar.xz"
           tar -cJf "$cikti" -C "$(dirname "$kaynak")" "$ad" 2>&1 ;;
        *) _hata "Geçersiz format!"; return 1 ;;
    esac
    [ -f "$cikti" ] && _basari "Arşiv oluşturuldu: $cikti ($(du -h "$cikti" | cut -f1))" || _hata "Arşiv oluşturulamadı."
    _log "BILGI" "Arşiv oluşturuldu: $cikti"
}

arsiv_ac() {
    echo -n -e "${YESIL}Arşiv dosyası: ${NC}"; read -r arsiv < /dev/tty
    arsiv=$(_path_genislet "$arsiv")
    [ ! -f "$arsiv" ] && { _hata "Dosya yok: $arsiv"; return 1; }
    echo -n -e "${YESIL}Hedef dizin (boş=burada): ${NC}"; read -r hedef < /dev/tty
    hedef=$(_path_genislet "${hedef:-$(dirname "$arsiv")}")
    mkdir -p "$hedef"
    case "$arsiv" in
        *.tar.gz|*.tgz) tar -xzf "$arsiv" -C "$hedef" 2>&1 ;;
        *.tar.bz2)       tar -xjf "$arsiv" -C "$hedef" 2>&1 ;;
        *.tar.xz)        tar -xJf "$arsiv" -C "$hedef" 2>&1 ;;
        *.tar)           tar -xf  "$arsiv" -C "$hedef" 2>&1 ;;
        *.zip)           unzip -o  "$arsiv" -d "$hedef" 2>&1 ;;
        *.7z)            7z x "$arsiv" -o"$hedef" 2>&1 ;;
        *) _hata "Desteklenmeyen format: $arsiv"; return 1 ;;
    esac
    [ $? -eq 0 ] && _basari "Çıkarıldı: $hedef" || _hata "Çıkarma başarısız."
    _log "BILGI" "Arşiv açıldı: $arsiv → $hedef"
}

sembolik_link_olustur() {
    echo -n -e "${YESIL}Kaynak dosya/dizin: ${NC}"; read -r kaynak < /dev/tty
    echo -n -e "${YESIL}Link adı/yolu:      ${NC}"; read -r link < /dev/tty
    kaynak=$(_path_genislet "$kaynak")
    link=$(_path_genislet "$link")
    [ ! -e "$kaynak" ] && { _hata "Kaynak bulunamadı: $kaynak"; return 1; }
    ln -sf "$kaynak" "$link" && _basari "Link oluşturuldu: $link → $kaynak" || _hata "Başarısız."
    _log "BILGI" "Sembolik link: $link → $kaynak"
}

toplu_yeniden_adlandir() {
    echo -n -e "${YESIL}Dizin yolu: ${NC}"; read -r dizin < /dev/tty
    dizin=$(_path_genislet "${dizin:-$HOME}")
    [ ! -d "$dizin" ] && { _hata "Dizin yok: $dizin"; return 1; }
    echo -n -e "${YESIL}Eski uzantı (örn: .txt): ${NC}"; read -r eski < /dev/tty
    echo -n -e "${YESIL}Yeni uzantı (örn: .bak): ${NC}"; read -r yeni < /dev/tty
    [ -z "$eski" ] && { _hata "Uzantı boş!"; return 1; }
    local sayac=0
    find "$dizin" -maxdepth 1 -name "*${eski}" -type f 2>/dev/null | while read -r f; do
        local yeni_ad="${f%$eski}${yeni}"
        mv "$f" "$yeni_ad" && echo "  ${YESIL}→${NC} $(basename "$yeni_ad")" && ((sayac++))
    done
    _basari "Yeniden adlandırma tamamlandı."
    _log "BILGI" "Toplu yeniden adlandırma: $eski → $yeni"
}

dosya_karsilastir() {
    echo -n -e "${YESIL}Dosya 1: ${NC}"; read -r f1 < /dev/tty
    echo -n -e "${YESIL}Dosya 2: ${NC}"; read -r f2 < /dev/tty
    f1=$(_path_genislet "$f1"); f2=$(_path_genislet "$f2")
    [ ! -f "$f1" ] && { _hata "Dosya 1 yok: $f1"; return 1; }
    [ ! -f "$f2" ] && { _hata "Dosya 2 yok: $f2"; return 1; }
    if diff -u "$f1" "$f2" | less -R; then
        _basari "Karşılaştırma tamamlandı."
    fi
    _log "BILGI" "Dosya karşılaştırma: $f1 vs $f2"
}

yinelenen_dosya_bul() {
    _bilgi "Yinelenen dosyalar aranıyor (MD5 karşılaştırma)..."
    _uyari "Bu işlem uzun sürebilir..."
    find "$HOME" -type f 2>/dev/null | while read -r f; do
        md5sum "$f" 2>/dev/null
    done | sort | uniq -d -w 32 | while read -r hash dosya; do
        echo -e "  ${SARI}$hash${NC}  $dosya"
    done | less -R
    _log "BILGI" "Yinelenen dosya arama tamamlandı"
}

# ─── EK SİSTEM FONKSİYONLARI ─────────────────────────────────

samsung_a34_bilgi() {
    _baslik "$TURKUAZ" "📱 SAMSUNG GALAXY A34 5G — SİSTEM BİLGİSİ"
    echo -e "${BEYAZ}=== Cihaz ===${NC}"
    command -v getprop &>/dev/null && {
        echo -e "${BEYAZ}Model:${NC}       $(getprop ro.product.model 2>/dev/null)"
        echo -e "${BEYAZ}Android:${NC}     $(getprop ro.build.version.release 2>/dev/null)"
        echo -e "${BEYAZ}SDK:${NC}         $(getprop ro.build.version.sdk 2>/dev/null)"
        echo -e "${BEYAZ}Güvenlik:${NC}    $(getprop ro.build.version.security_patch 2>/dev/null)"
        echo -e "${BEYAZ}Build:${NC}       $(getprop ro.build.display.id 2>/dev/null)"
        echo -e "${BEYAZ}Fingerprint:${NC} $(getprop ro.build.fingerprint 2>/dev/null)"
        echo -e "${BEYAZ}CPU ABI:${NC}     $(getprop ro.product.cpu.abi 2>/dev/null)"
        echo -e "${BEYAZ}Ekran DPI:${NC}   $(getprop ro.sf.lcd_density 2>/dev/null)"
    }
    echo ""
    echo -e "${BEYAZ}=== CPU (Exynos 1280) ===${NC}"
    grep -m1 "Hardware" /proc/cpuinfo 2>/dev/null | sed 's/Hardware\s*:\s*/  CPU: /'
    echo -e "  Çekirdek sayısı: $(nproc 2>/dev/null || grep -c processor /proc/cpuinfo 2>/dev/null)"
    echo -e "  CPU frekansı:    $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | awk '{printf "%.0f MHz\n", $1/1000}' || echo 'N/A')"
    echo -e "  Max frekans:     $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null | awk '{printf "%.0f MHz\n", $1/1000}' || echo 'N/A')"
    echo ""
    echo -e "${BEYAZ}=== Bellek ===${NC}"
    free -h 2>/dev/null | awk '/^Mem/{printf "  RAM:  %s / %s (kullanılan/toplam)\n", $3, $2}'
    echo ""
    echo -e "${BEYAZ}=== Depolama ===${NC}"
    df -h ~ 2>/dev/null | awk 'NR==2{printf "  /data: %s / %s (%s kullanılan)\n", $3, $2, $5}'
    [ -d /sdcard ] && df -h /sdcard 2>/dev/null | awk 'NR==2{printf "  /sdcard: %s / %s (%s kullanılan)\n", $3, $2, $5}'
    echo ""
    echo -e "${BEYAZ}=== Termux Ortamı ===${NC}"
    echo -e "  Termux Prefix: $PREFIX"
    echo -e "  Bash:          $(bash --version | head -1)"
    echo -e "  Kernel:        $(uname -r)"
    _log "BILGI" "Samsung A34 sistem bilgisi görüntülendi"
    _bekle
}

sistem_performans() {
    _baslik "$TURKUAZ" "⚡ SİSTEM PERFORMANSI"
    echo -e "${BEYAZ}=== CPU Yük Ortalaması ===${NC}"
    local load; load=$(cat /proc/loadavg 2>/dev/null)
    local l1 l5 l15; l1=$(echo "$load" | cut -d' ' -f1); l5=$(echo "$load" | cut -d' ' -f2); l15=$(echo "$load" | cut -d' ' -f3)
    echo -e "  1 dk:  ${YESIL}$l1${NC}   5 dk: ${YESIL}$l5${NC}   15 dk: ${YESIL}$l15${NC}"
    echo ""
    echo -e "${BEYAZ}=== Çalışan Süreç Sayısı ===${NC}"
    echo -e "  Toplam: $(ps aux 2>/dev/null | wc -l)"
    echo ""
    echo -e "${BEYAZ}=== Bellek Detayı ===${NC}"
    cat /proc/meminfo 2>/dev/null | grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree" | \
    while read -r satir; do
        printf "  %-20s %s\n" "$(echo "$satir" | cut -d: -f1):" \
            "$(echo "$satir" | awk '{printf "%.0f MB", $2/1024}')"
    done
    echo ""
    echo -e "${BEYAZ}=== Disk I/O (son 5 sn) ===${NC}"
    if [ -f /proc/diskstats ]; then
        local once_r once_w sonra_r sonra_w
        once_r=$(awk '{sum+=$6} END{print sum}' /proc/diskstats 2>/dev/null)
        once_w=$(awk '{sum+=$10} END{print sum}' /proc/diskstats 2>/dev/null)
        sleep 1
        sonra_r=$(awk '{sum+=$6} END{print sum}' /proc/diskstats 2>/dev/null)
        sonra_w=$(awk '{sum+=$10} END{print sum}' /proc/diskstats 2>/dev/null)
        local diff_r=$(( (sonra_r - once_r) * 512 ))
        local diff_w=$(( (sonra_w - once_w) * 512 ))
        echo -e "  Okuma:  $(numfmt --to=iec $diff_r 2>/dev/null || echo "${diff_r}B")/sn"
        echo -e "  Yazma:  $(numfmt --to=iec $diff_w 2>/dev/null || echo "${diff_w}B")/sn"
    else
        echo "  Disk I/O bilgisi alınamadı."
    fi
    echo ""
    echo -e "${BEYAZ}=== En Çok CPU Kullanan 5 İşlem ===${NC}"
    ps aux 2>/dev/null | sort -nrk 3,3 | head -5 | awk '{printf "  %-20s CPU: %s%%  RAM: %s%%\n", $11, $3, $4}'
    _log "BILGI" "Sistem performansı görüntülendi"
    _bekle
}

ag_hizi_olc() {
    _bilgi "Ağ hızı ölçülüyor..."
    echo -e "${BEYAZ}İndirme hızı (10MB test):${NC}"
    local hiz
    hiz=$(curl -o /dev/null -w "%{speed_download}" -s --connect-timeout 10 \
        http://speedtest.tele2.net/10MB.zip 2>/dev/null)
    if [ -n "$hiz" ] && [ "$hiz" != "0" ]; then
        printf "  İndirme: ${YESIL}%.2f MB/sn${NC}\n" "$(echo "$hiz" | awk '{printf "%.2f", $1/1024/1024}')"
        printf "  İndirme: ${YESIL}%.1f Mbps${NC}\n" "$(echo "$hiz" | awk '{printf "%.1f", $1*8/1000000}')"
    else
        _hata "Hız testi başarısız."
    fi
    _log "BILGI" "Ağ hızı ölçüldü"
}

# ─── EK ANDROID FONKSİYONLARI (Samsung A34 5G) ───────────────

wifi_bilgi() {
    _api_kontrol || return 1
    _bilgi "Wi-Fi bilgisi alınıyor..."
    termux-wifi-connectioninfo 2>/dev/null | \
        { command -v jq &>/dev/null && jq . || cat; } || \
        _hata "Wi-Fi bilgisi alınamadı."
    _log "BILGI" "Wi-Fi bilgisi"
}

wifi_tara() {
    _api_kontrol || return 1
    _bilgi "Çevredeki Wi-Fi ağları taranıyor..."
    termux-wifi-scaninfo 2>/dev/null | \
        { command -v jq &>/dev/null && jq '.[].ssid' || cat; } || \
        _hata "Wi-Fi tarama başarısız."
    _log "BILGI" "Wi-Fi tarama"
}

sensor_bilgi() {
    _api_kontrol || return 1
    _bilgi "Sensör listesi alınıyor..."
    termux-sensor -l 2>/dev/null || _hata "Sensör bilgisi alınamadı."
    _log "BILGI" "Sensör listesi"
}

kamera_bilgi() {
    _api_kontrol || return 1
    _bilgi "Kamera bilgisi:"
    termux-camera-info 2>/dev/null | \
        { command -v jq &>/dev/null && jq . || cat; } || \
        _hata "Kamera bilgisi alınamadı."
    _log "BILGI" "Kamera bilgisi"
}

acik_uygulamalar() {
    _bilgi "Çalışan Android uygulamaları:"
    termux-toast "Uygulama listesi alınıyor..." 2>/dev/null
    ps aux 2>/dev/null | grep -v grep | grep -v termux | head -30
    _log "BILGI" "Açık uygulamalar görüntülendi"
}

pil_detay() {
    _api_kontrol || return 1
    _bilgi "Detaylı pil bilgisi:"
    local pil_json
    pil_json=$(termux-battery-status 2>/dev/null)
    if [ -n "$pil_json" ]; then
        if command -v jq &>/dev/null; then
            echo "$pil_json" | jq .
            local yuzde; yuzde=$(echo "$pil_json" | jq '.percentage' 2>/dev/null)
            echo ""
            # Pil seviye görsel bar
            local bar="" i
            for ((i=0; i<yuzde/5; i++)); do bar+="█"; done
            for ((i=yuzde/5; i<20; i++)); do bar+="░"; done
            if   [ "${yuzde:-0}" -gt 60 ]; then echo -e "  ${YESIL}[$bar] %$yuzde${NC}"
            elif [ "${yuzde:-0}" -gt 20 ]; then echo -e "  ${SARI}[$bar] %$yuzde${NC}"
            else                               echo -e "  ${KIRMIZI}[$bar] %$yuzde${NC}"
            fi
        else
            echo "$pil_json"
        fi
    else
        _hata "Pil bilgisi alınamadı."
    fi
    _log "BILGI" "Pil detayı görüntülendi"
}

ekran_parlaklik() {
    _bilgi "Ekran parlaklığı (Samsung A34 5G):"
    local mevcut
    mevcut=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1 || \
             cat /sys/devices/platform/*/leds/lcd-backlight/brightness 2>/dev/null | head -1 || \
             echo "N/A")
    local max_val
    max_val=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1 || echo "255")
    echo -e "${BEYAZ}Mevcut:${NC} $mevcut / $max_val"
    if [ "$mevcut" != "N/A" ] && [ "$max_val" -gt 0 ] 2>/dev/null; then
        local yuzde=$(( mevcut * 100 / max_val ))
        echo -e "${BEYAZ}Yüzde:${NC}  %$yuzde"
    fi
    echo ""
    _bilgi "Parlaklığı değiştirmek için termux-api yükleyin ve termux-screen-brightness kullanın."
}

termux_bildirim_gonder() {
    _api_kontrol || return 1
    echo -n -e "${YESIL}Başlık:  ${NC}"; read -r baslik < /dev/tty
    echo -n -e "${YESIL}İçerik: ${NC}"; read -r icerik < /dev/tty
    echo -n -e "${YESIL}ID (boş=otomatik): ${NC}"; read -r bildirim_id < /dev/tty
    local cmd="termux-notification -t \"$baslik\" -c \"$icerik\""
    [ -n "$bildirim_id" ] && cmd="$cmd --id $bildirim_id"
    eval "$cmd" 2>/dev/null && _basari "Bildirim gönderildi." || _hata "Başarısız."
    _log "BILGI" "Gelişmiş bildirim: $baslik"
}

media_tara() {
    _api_kontrol || return 1
    _bilgi "Android medya kütüphanesi taranıyor..."
    termux-media-scan "${1:-/sdcard}" 2>/dev/null && _basari "Medya taraması tamamlandı." || \
        _hata "Tarama başarısız. (termux-setup-storage gerekebilir)"
    _log "BILGI" "Medya tarama"
}

# ─── EK GÜVENLİK FONKSİYONLARI ───────────────────────────────

whois_sorgula() {
    local d="$1"
    [ -z "$d" ] && { echo -n -e "${YESIL}Domain/IP: ${NC}"; read -r d < /dev/tty; }
    [ -z "$d" ] && { _hata "Domain boş!"; return 1; }
    if command -v whois &>/dev/null; then
        whois "$d" | less -R
    else
        _bilgi "whois yüklü değil. Kuruluyor..."
        pkg install -y whois &>/dev/null && whois "$d" | less -R || \
            curl -s "https://www.whois.com/whois/$d" | grep -o '<p>[^<]*</p>' | sed 's/<[^>]*>//g' | head -20
    fi
    _log "BILGI" "WHOIS: $d"
}

http_baslik_kontrol() {
    local url="$1"
    [ -z "$url" ] && { echo -n -e "${YESIL}URL: ${NC}"; read -r url < /dev/tty; }
    [ -z "$url" ] && { _hata "URL boş!"; return 1; }
    _bilgi "HTTP başlıkları: $url"
    curl -I --connect-timeout 10 -s "$url" | less -R || _hata "Başarısız."
    _log "BILGI" "HTTP başlık: $url"
}

aktif_ag_arayuzleri() {
    echo -e "${BEYAZ}=== Aktif Ağ Arayüzleri ===${NC}"
    if command -v ip &>/dev/null; then
        ip -c addr show 2>/dev/null | grep -E "^[0-9]|inet " | head -30 | less -R
    else
        ifconfig 2>/dev/null | less -R
    fi
    echo ""
    echo -e "${BEYAZ}=== Yönlendirme Tablosu ===${NC}"
    ip route 2>/dev/null || route 2>/dev/null || netstat -r 2>/dev/null
    _log "BILGI" "Ağ arayüzleri görüntülendi"
}

guvenli_sifre_uret() {
    echo -n -e "${YESIL}Şifre uzunluğu [16]: ${NC}"; read -r uzunluk < /dev/tty
    uzunluk="${uzunluk:-16}"
    echo -n -e "${YESIL}Özel karakter dahil? (e/h) [e]: ${NC}"; read -r ozel < /dev/tty
    local charset
    if [[ "$ozel" == "h" || "$ozel" == "H" ]]; then
        charset='A-Za-z0-9'
    else
        charset='A-Za-z0-9!@#$%^&*()_+-=[]{}|;:,.<>?'
    fi
    echo ""
    echo -e "${BEYAZ}Üretilen şifreler:${NC}"
    for i in 1 2 3 4 5; do
        local sifre
        sifre=$(tr -dc "$charset" < /dev/urandom 2>/dev/null | head -c "$uzunluk")
        echo -e "  ${YESIL}$i.${NC}  $sifre"
    done
    echo ""
    _bilgi "Şifreyi panoya kopyalamak için üstteki metni seçin."
    _log "BILGI" "Güvenli şifre üretildi"
}

md5_sha_hesapla() {
    local f="$1"
    [ -z "$f" ] && { echo -n -e "${YESIL}Dosya yolu: ${NC}"; read -r f < /dev/tty; }
    f=$(_path_genislet "$f")
    [ ! -f "$f" ] && { _hata "Dosya yok: $f"; return 1; }
    echo -e "${BEYAZ}Dosya:${NC} $f"
    echo -e "${BEYAZ}Boyut:${NC} $(du -h "$f" | cut -f1)"
    echo ""
    echo -e "${BEYAZ}MD5:${NC}    $(md5sum "$f" 2>/dev/null | cut -d' ' -f1 || echo 'N/A')"
    echo -e "${BEYAZ}SHA1:${NC}   $(sha1sum "$f" 2>/dev/null | cut -d' ' -f1 || echo 'N/A')"
    echo -e "${BEYAZ}SHA256:${NC} $(sha256sum "$f" 2>/dev/null | cut -d' ' -f1 || echo 'N/A')"
    _log "BILGI" "Hash hesaplandı: $f"
}

# ─── EK YEDEKLEME FONKSİYONLARI ───────────────────────────────

sifreli_yedek_al() {
    command -v openssl &>/dev/null || { _hata "openssl yok. Kurmak için: pkg install openssl"; return 1; }
    local hedef="$1"
    [ -z "$hedef" ] && { echo -n -e "${YESIL}Yedeklenecek dizin: ${NC}"; read -r hedef < /dev/tty; }
    hedef=$(_path_genislet "$hedef")
    [ ! -d "$hedef" ] && { _hata "Dizin yok: $hedef"; return 1; }
    echo -n -e "${YESIL}Şifre: ${NC}"; read -rs sifre < /dev/tty; echo ""
    [ -z "$sifre" ] && { _hata "Şifre boş olamaz!"; return 1; }
    local ad; ad=$(basename "$hedef")
    local dosya="$YEDEK_KOKU/${ad}_sifrelii_$(date +%Y%m%d_%H%M%S).tar.gz.enc"
    _bilgi "Şifreli yedek oluşturuluyor..."
    tar -czf - -C "$(dirname "$hedef")" "$ad" 2>/dev/null | \
        openssl enc -aes-256-cbc -pbkdf2 -k "$sifre" > "$dosya" 2>/dev/null
    if [ -f "$dosya" ] && [ -s "$dosya" ]; then
        _basari "Şifreli yedek: $dosya ($(du -h "$dosya" | cut -f1))"
        _bilgi "Geri yüklemek: openssl enc -d -aes-256-cbc -pbkdf2 -k SIFRE -in $dosya | tar -xzf -"
    else
        _hata "Şifreli yedek oluşturulamadı."
        return 1
    fi
    _log "BILGI" "Şifreli yedek: $dosya"
}

yedek_boyut_analiz() {
    _bilgi "Yedek dizini analiz ediliyor..."
    if [ ! -d "$YEDEK_KOKU" ]; then
        _bilgi "Yedek dizini boş."
        return 0
    fi
    echo -e "${BEYAZ}Yedek boyutları:${NC}"
    du -sh "$YEDEK_KOKU"/* 2>/dev/null | sort -hr | while read -r boyut dosya; do
        printf "  ${BEYAZ}%-10s${NC} %s\n" "$boyut" "$(basename "$dosya")"
    done
    echo ""
    echo -e "${BEYAZ}Toplam:${NC} $(du -sh "$YEDEK_KOKU" 2>/dev/null | cut -f1)"
    echo -e "${BEYAZ}Adet:${NC}   $(find "$YEDEK_KOKU" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l)"
    _log "BILGI" "Yedek boyut analizi"
}

# ─── EK TEMİZLİK FONKSİYONLARI ───────────────────────────────

buyuk_dosya_sil() {
    echo -n -e "${YESIL}Minimum boyut (örn: 50M, 1G) [100M]: ${NC}"; read -r boyut < /dev/tty
    boyut="${boyut:-100M}"
    _bilgi "Büyük dosyalar aranıyor (>${boyut})..."
    mapfile -t dosyalar < <(find "$HOME" -type f -size "+${boyut}" 2>/dev/null | sort)
    if [ ${#dosyalar[@]} -eq 0 ]; then
        _bilgi "Bu boyutun üzerinde dosya bulunamadı."
        return 0
    fi
    echo -e "${BEYAZ}Bulunanlar:${NC}"
    for i in "${!dosyalar[@]}"; do
        printf "  ${BEYAZ}%2d.${NC}  %-8s %s\n" "$((i+1))" \
            "$(du -h "${dosyalar[$i]}" 2>/dev/null | cut -f1)" "${dosyalar[$i]}"
    done
    echo ""
    echo -n -e "${YESIL}Silinecek numara (0=hepsi sil, q=iptal): ${NC}"; read -r sec < /dev/tty
    case $sec in
        q|Q) _bilgi "İptal." ;;
        0)
            _onay "TÜMÜ silinsin mi?" && {
                for f in "${dosyalar[@]}"; do rm -f "$f" && echo "  Silindi: $f"; done
                _basari "Temizlik tamamlandı."
            } ;;
        *)
            local f="${dosyalar[$((sec-1))]}"
            [ -f "$f" ] && _onay "'$f' silinsin mi?" && rm -f "$f" && _basari "Silindi." || _hata "Geçersiz."
            ;;
    esac
    _log "BILGI" "Büyük dosya temizliği"
}

android_onbellek_temizle() {
    _bilgi "Android uygulama önbellekleri temizleniyor..."
    if [ -d ~/storage/Android/data ]; then
        _onay "Android önbellekleri temizlensin mi?" && {
            find ~/storage/Android/data -name "cache" -type d 2>/dev/null | while read -r d; do
                rm -rf "$d"/* 2>/dev/null && echo "  Temizlendi: $d"
            done
            _basari "Android önbellekleri temizlendi."
        }
    else
        _bilgi "Depolama erişimi yok. Önce termux-setup-storage çalıştırın."
    fi
    # Termux kendi önbelleklerini temizle
    find "$KONFIG_DIZINI" -name "*.tmp" -delete 2>/dev/null
    find /tmp -name "termux-*" -delete 2>/dev/null
    _basari "Termux geçici dosyaları temizlendi."
    _log "BILGI" "Android+Termux önbellek temizliği"
}

indirilen_apk_bul() {
    _bilgi "APK dosyaları aranıyor..."
    local yerler=(
        ~/storage/downloads
        ~/storage/shared
        ~/Downloads
        "$HOME"
    )
    for yer in "${yerler[@]}"; do
        [ -d "$yer" ] && find "$yer" -name "*.apk" 2>/dev/null | while read -r f; do
            printf "  %-8s %s\n" "$(du -h "$f" | cut -f1)" "$f"
        done
    done | less -R
    _log "BILGI" "APK dosyası arama"
}

# ─── GELİŞMİŞ ALT MENÜLER ────────────────────────────────────

modul_dosya_ek() {
    while true; do
        _baslik "$YESIL" "📁 GELİŞMİŞ DOSYA İŞLEMLERİ"
        echo -e "  ${BEYAZ}[1]${NC}  Arşiv oluştur (.tar.gz/.zip/.tar.bz2/.tar.xz)"
        echo -e "  ${BEYAZ}[2]${NC}  Arşiv aç (otomatik format tespiti)"
        echo -e "  ${BEYAZ}[3]${NC}  Sembolik link oluştur"
        echo -e "  ${BEYAZ}[4]${NC}  Toplu dosya yeniden adlandır"
        echo -e "  ${BEYAZ}[5]${NC}  İki dosyayı karşılaştır (diff)"
        echo -e "  ${BEYAZ}[6]${NC}  Yinelenen dosya bul (MD5)"
        echo -e "  ${BEYAZ}[7]${NC}  MD5/SHA hash hesapla"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-7]: ${NC}"; read -r s < /dev/tty
        case $s in
            1) arsiv_olustur; _bekle ;;
            2) arsiv_ac; _bekle ;;
            3) sembolik_link_olustur; _bekle ;;
            4) toplu_yeniden_adlandir; _bekle ;;
            5) dosya_karsilastir; _bekle ;;
            6) yinelenen_dosya_bul; _bekle ;;
            7) md5_sha_hesapla; _bekle ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

modul_sistem_ek() {
    while true; do
        _baslik "$TURKUAZ" "🔧 GELİŞMİŞ SİSTEM İZLEME"
        echo -e "  ${BEYAZ}[1]${NC}  Samsung Galaxy A34 5G özel bilgi"
        echo -e "  ${BEYAZ}[2]${NC}  Sistem performansı (CPU/RAM/Disk I/O)"
        echo -e "  ${BEYAZ}[3]${NC}  Ağ hızı ölçümü"
        echo -e "  ${BEYAZ}[4]${NC}  Aktif ağ arayüzleri ve rota tablosu"
        echo -e "  ${BEYAZ}[5]${NC}  Güvenli şifre üret"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-5]: ${NC}"; read -r s < /dev/tty
        case $s in
            1) samsung_a34_bilgi ;;
            2) sistem_performans ;;
            3) ag_hizi_olc; _bekle ;;
            4) aktif_ag_arayuzleri; _bekle ;;
            5) guvenli_sifre_uret; _bekle ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

modul_android_ek() {
    while true; do
        _baslik "$TURKUAZ" "📱 GELİŞMİŞ ANDROİD İŞLEMLERİ (Samsung A34 5G)"
        echo -e "  ${BEYAZ}[1]${NC}  Wi-Fi bağlantı bilgisi"
        echo -e "  ${BEYAZ}[2]${NC}  Çevredeki Wi-Fi ağlarını tara"
        echo -e "  ${BEYAZ}[3]${NC}  Sensör listesi"
        echo -e "  ${BEYAZ}[4]${NC}  Kamera bilgisi"
        echo -e "  ${BEYAZ}[5]${NC}  Detaylı pil durumu (grafik bar)"
        echo -e "  ${BEYAZ}[6]${NC}  Ekran parlaklığı bilgisi"
        echo -e "  ${BEYAZ}[7]${NC}  Gelişmiş bildirim gönder (ID ile)"
        echo -e "  ${BEYAZ}[8]${NC}  Android medya kütüphanesi tara"
        echo -e "  ${BEYAZ}[9]${NC}  APK dosyalarını bul"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-9]: ${NC}"; read -r s < /dev/tty
        case $s in
            1) wifi_bilgi; _bekle ;;
            2) wifi_tara; _bekle ;;
            3) sensor_bilgi; _bekle ;;
            4) kamera_bilgi; _bekle ;;
            5) pil_detay; _bekle ;;
            6) ekran_parlaklik; _bekle ;;
            7) termux_bildirim_gonder; _bekle ;;
            8) media_tara; _bekle ;;
            9) indirilen_apk_bul; _bekle ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

modul_guvenlik_ek() {
    while true; do
        _baslik "$MOR" "🔍 GELİŞMİŞ GÜVENLİK ARAÇLARI"
        echo -e "  ${BEYAZ}[1]${NC}  WHOIS sorgusu (domain/IP)"
        echo -e "  ${BEYAZ}[2]${NC}  HTTP başlıklarını kontrol et"
        echo -e "  ${BEYAZ}[3]${NC}  Aktif ağ arayüzleri + rota"
        echo -e "  ${BEYAZ}[4]${NC}  MD5/SHA hash hesapla"
        echo -e "  ${BEYAZ}[5]${NC}  Güvenli şifre üret"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-5]: ${NC}"; read -r s < /dev/tty
        case $s in
            1) whois_sorgula; _bekle ;;
            2) http_baslik_kontrol; _bekle ;;
            3) aktif_ag_arayuzleri; _bekle ;;
            4) md5_sha_hesapla; _bekle ;;
            5) guvenli_sifre_uret; _bekle ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

modul_yedek_ek() {
    while true; do
        _baslik "$YESIL" "💾 GELİŞMİŞ YEDEKLEME"
        echo -e "  ${BEYAZ}[1]${NC}  Şifreli yedek al (AES-256)"
        echo -e "  ${BEYAZ}[2]${NC}  Yedek boyut analizi"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-2]: ${NC}"; read -r s < /dev/tty
        case $s in
            1) sifreli_yedek_al; _bekle ;;
            2) yedek_boyut_analiz; _bekle ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

modul_temizlik_ek() {
    while true; do
        _baslik "$KIRMIZI" "🧹 GELİŞMİŞ TEMİZLİK"
        echo -e "  ${BEYAZ}[1]${NC}  Büyük dosyaları bul ve sil"
        echo -e "  ${BEYAZ}[2]${NC}  Yinelenen dosyaları bul (MD5)"
        echo -e "  ${BEYAZ}[3]${NC}  Android uygulama önbellekleri temizle"
        echo -e "  ${BEYAZ}[4]${NC}  APK dosyalarını bul"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-4]: ${NC}"; read -r s < /dev/tty
        case $s in
            1) buyuk_dosya_sil; _bekle ;;
            2) yinelenen_dosya_bul; _bekle ;;
            3) android_onbellek_temizle; _bekle ;;
            4) indirilen_apk_bul; _bekle ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

modul_paket_ek() {
    while true; do
        _baslik "$MAVI" "📦 GELİŞMİŞ PAKET İŞLEMLERİ"
        echo -e "  ${BEYAZ}[1]${NC}  Paket detaylı bilgisi (pkg show)"
        echo -e "  ${BEYAZ}[2]${NC}  Paket bağımlılıkları"
        echo -e "  ${BEYAZ}[3]${NC}  Paketin dosyaları"
        echo -e "  ${BEYAZ}[4]${NC}  Komut hangi pakette?"
        echo -e "  ${BEYAZ}[5]${NC}  Paket istatistikleri (yüklü araçlar)"
        echo -e "  ${BEYAZ}[6]${NC}  Popüler paket hızlı kurulum"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-6]: ${NC}"; read -r s < /dev/tty
        case $s in
            1) paket_bilgi; _bekle ;;
            2) paket_bagimlilik; _bekle ;;
            3) paket_dosyalari; _bekle ;;
            4) paket_hangi_pakette; _bekle ;;
            5) paket_istatistik; _bekle ;;
            6) paket_populer_kur; _bekle ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# EKSİK FONKSİYONLAR — YÜKLENEN SCRİPTTEN EKLENDI
# ============================================================

# ─── YARDIMCI ────────────────────────────────────────────────
_boyut_formatla() {
    local b="$1"
    [ -z "$b" ] || [ "$b" = "0" ] && { echo "0B"; return; }
    if   [ "$b" -ge 1073741824 ] 2>/dev/null; then awk "BEGIN{printf \"%.2fGB\",$b/1073741824}"
    elif [ "$b" -ge 1048576    ] 2>/dev/null; then awk "BEGIN{printf \"%.2fMB\",$b/1048576}"
    elif [ "$b" -ge 1024       ] 2>/dev/null; then awk "BEGIN{printf \"%.2fKB\",$b/1024}"
    else echo "${b}B"; fi
}

_zaman_formatla() {
    local s="$1"
    local h=$(( s/3600 )) m=$(( (s%3600)/60 )) k=$(( s%60 ))
    [ $h -gt 0 ] && printf "%02d:%02d:%02d" $h $m $k && return
    [ $m -gt 0 ] && printf "%02d:%02d" $m $k && return
    printf "%02d sn" $k
}

_progress_bar() {
    local cur="$1" tot="$2" w="${3:-30}"
    local pct=$(( cur*100/tot )) dolu=$(( cur*w/tot )) bos=$(( w - dolu ))
    printf "\r  ["; printf "%${dolu}s"|tr ' ' '█'; printf "%${bos}s"|tr ' ' '░'; printf "] %3d%%" "$pct"
}

_galaxy_kontrol() {
    local m; m=$(getprop ro.product.model 2>/dev/null || echo "")
    [[ "$m" == *"A34"* ]] || [[ "$m" == *"SM-A346"* ]] && return 0
    return 1
}

_performans_olc() {
    local s e
    s=$(date +%s%N 2>/dev/null || echo 0)
    eval "$1" >/dev/null 2>&1
    e=$(date +%s%N 2>/dev/null || echo 0)
    echo $(( (e-s)/1000000 ))
}

_internet_kontrol() {
    ping -c 1 -W 5 8.8.8.8 &>/dev/null && return 0
    _uyari "İnternet bağlantısı yok!"; return 1
}

# ─── EKSİK PAKET ─────────────────────────────────────────────
paket_versiyon() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Paket: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && return 1
    dpkg -l "$p" 2>/dev/null | tail -1 | awk '{print $3}' || _hata "Bulunamadı."
}

paket_arama_detayli() {
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Arama terimi: ${NC}"; read -r p < /dev/tty; }
    [ -z "$p" ] && return 1
    apt-cache search "$p" 2>/dev/null | head -50 | less -R
}

pip_ortam_olustur() {
    local ad="$1"
    [ -z "$ad" ] && { echo -n -e "${YESIL}Sanal ortam adı: ${NC}"; read -r ad < /dev/tty; }
    [ -z "$ad" ] && return 1
    python3 -m venv "$ad" 2>/dev/null && _basari "Sanal ortam: $ad" || _hata "Başarısız. python3 kurulu mu?"
}

pip_freeze() {
    local pip_cmd; pip_cmd=$(command -v pip3 2>/dev/null || command -v pip)
    [ -z "$pip_cmd" ] && { _hata "pip yok!"; return 1; }
    local f="$HOME/requirements_$(date +%Y%m%d).txt"
    $pip_cmd freeze 2>/dev/null > "$f" && _basari "Kaydedildi: $f" || _hata "Başarısız."
}

npm_guncelle() {
    command -v npm &>/dev/null || { _hata "npm yok!"; return 1; }
    local p="$1"
    if [ -z "$p" ]; then
        npm update -g 2>&1 && _basari "Tümü güncellendi." || _hata "Başarısız."
    else
        npm update -g "$p" 2>&1 && _basari "$p güncellendi." || _hata "Başarısız."
    fi
}

npm_versiyon() {
    command -v npm &>/dev/null || { _hata "npm yok!"; return 1; }
    local p="$1"
    [ -z "$p" ] && { echo -n -e "${YESIL}Paket: ${NC}"; read -r p < /dev/tty; }
    npm list -g "$p" --depth=0 2>/dev/null || _hata "Bulunamadı."
}

# ─── EKSİK GİT ───────────────────────────────────────────────
git_log_goster() {
    local pd="$1"
    [ -z "$pd" ] && { echo -n -e "${YESIL}Proje dizini: ${NC}"; read -r pd < /dev/tty; }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    git -C "$pd" log --oneline --graph --color=always -30 2>/dev/null | less -R
    _log "BILGI" "Git log: $pd"
}

git_diff_goster() {
    local pd="$1"
    [ -z "$pd" ] && { echo -n -e "${YESIL}Proje dizini: ${NC}"; read -r pd < /dev/tty; }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    git -C "$pd" diff --color=always 2>/dev/null | less -R
    _log "BILGI" "Git diff: $pd"
}

git_remote_listele() {
    local pd="$1"
    [ -z "$pd" ] && { echo -n -e "${YESIL}Proje dizini: ${NC}"; read -r pd < /dev/tty; }
    pd=$(_path_genislet "$pd")
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    git -C "$pd" remote -v 2>/dev/null || _bilgi "Remote yok."
    _bekle; _log "BILGI" "Git remote: $pd"
}

git_stash_yonet() {
    local pd="$1"
    [ -z "$pd" ] && { echo -n -e "${YESIL}Proje dizini: ${NC}"; read -r pd < /dev/tty; }
    pd=$(_path_genislet "$pd"); cd "$pd" 2>/dev/null || return 1
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    echo -e "${BEYAZ}Stash listesi:${NC}"; git stash list 2>/dev/null; echo ""
    echo -e "  ${BEYAZ}[1]${NC} Kaydet  ${BEYAZ}[2]${NC} Uygula  ${BEYAZ}[3]${NC} Sil  ${BEYAZ}[0]${NC} Geri"
    echo -n -e "${YESIL}Seçim: ${NC}"; read -r sec < /dev/tty
    case $sec in
        1) echo -n "Mesaj: "; read -r msg < /dev/tty
           git stash push -m "${msg:-stash}" 2>&1 && _basari "Kaydedildi." || _hata "Başarısız." ;;
        2) git stash pop 2>&1 && _basari "Uygulandı." || _hata "Başarısız." ;;
        3) git stash drop 2>&1 && _basari "Silindi." || _hata "Başarısız." ;;
    esac
    cd - &>/dev/null; _log "BILGI" "Git stash: $pd"
}

git_tag_yonet() {
    local pd="$1"
    [ -z "$pd" ] && { echo -n -e "${YESIL}Proje dizini: ${NC}"; read -r pd < /dev/tty; }
    pd=$(_path_genislet "$pd"); cd "$pd" 2>/dev/null || return 1
    [ ! -d "$pd/.git" ] && { _hata "Git projesi değil: $pd"; return 1; }
    echo -e "${BEYAZ}Tag'ler:${NC}"; git tag 2>/dev/null | head -20; echo ""
    echo -e "  ${BEYAZ}[1]${NC} Oluştur  ${BEYAZ}[2]${NC} Sil  ${BEYAZ}[3]${NC} Push  ${BEYAZ}[0]${NC} Geri"
    echo -n -e "${YESIL}Seçim: ${NC}"; read -r sec < /dev/tty
    case $sec in
        1) echo -n "Tag: "; read -r t < /dev/tty; git tag "$t" 2>&1 && _basari "Oluşturuldu: $t" || _hata "Başarısız." ;;
        2) echo -n "Tag: "; read -r t < /dev/tty; git tag -d "$t" 2>&1 && _basari "Silindi: $t" || _hata "Başarısız." ;;
        3) echo -n "Tag: "; read -r t < /dev/tty; git push origin "$t" 2>&1 && _basari "Push: $t" || _hata "Başarısız." ;;
    esac
    cd - &>/dev/null; _log "BILGI" "Git tag: $pd"
}

# ─── EKSİK DOSYA ─────────────────────────────────────────────
dosya_olustur() {
    echo -n -e "${YESIL}Dosya adı: ${NC}"; read -r ad < /dev/tty
    ad=$(_path_genislet "$ad")
    [ -z "$ad" ] && { _hata "Boş!"; return 1; }
    [ -e "$ad" ] && { _uyari "Zaten var."; _onay "Üzerine yaz?" || return 0; }
    touch "$ad" && _basari "Oluşturuldu: $ad" || _hata "Başarısız."
    _log "BILGI" "Dosya oluşturuldu: $ad"
}

# ─── EKSİK ALIAS ─────────────────────────────────────────────
alias_grup_uygula() {
    [ ! -f "$ALIAS_GRUPLAR" ] && { _bilgi "Grup yok."; return 0; }
    cat -n "$ALIAS_GRUPLAR"
    echo -n -e "${YESIL}Uygulanacak grup numarası: ${NC}"; read -r num < /dev/tty
    local grup aliaslar
    grup=$(sed -n "${num}p" "$ALIAS_GRUPLAR" | cut -d: -f1)
    aliaslar=$(sed -n "${num}p" "$ALIAS_GRUPLAR" | cut -d: -f2)
    [ -n "$grup" ] && _basari "Grup '$grup' uygulanıyor: $aliaslar" || _hata "Geçersiz."
}

alias_import_bashrc() {
    local rc="$HOME/.bashrc"
    [ ! -f "$rc" ] && { _hata ".bashrc bulunamadı"; return 1; }
    grep "^alias " "$rc" | sed 's/^alias //' >> "$ALIAS_LISTESI" 2>/dev/null
    _basari "Aliaslar import edildi."
    _log "BILGI" "Alias import: $rc"
}

# ─── EKSİK SCRİPT ────────────────────────────────────────────
script_kategori_ekle() {
    local s="$1" kat="$2"
    [ -z "$s" ]   && { echo -n "Script: ";    read -r s   < /dev/tty; }
    [ -z "$kat" ] && { echo -n "Kategori: "; read -r kat < /dev/tty; }
    s=$(_path_genislet "$s")
    [ ! -f "$s" ] && { _hata "Dosya yok: $s"; return 1; }
    echo "$kat:$s" >> "$KONFIG_DIZINI/kategoriler.txt" 2>/dev/null
    _basari "Kategori eklendi: $kat"
    _log "BILGI" "Script kategori: $kat:$s"
}

script_kategori_liste() {
    local f="$KONFIG_DIZINI/kategoriler.txt"
    [ ! -f "$f" ] && { _bilgi "Kategori yok."; return 0; }
    sort "$f" | while IFS=: read -r kat script; do
        [ -f "$script" ] && echo -e "  ${BEYAZ}$kat${NC}: $script" \
                         || echo -e "  ${GRI}$kat${NC}: ${KIRMIZI}$script [YOK]${NC}"
    done | less -R
}

_script_sablon_olustur() {
    local ad="$1"
    [ -z "$ad" ] && { echo -n "Şablon adı: "; read -r ad < /dev/tty; }
    [ -z "$ad" ] && return 1
    local dosya="$KONFIG_DIZINI/sablon_${ad}.sh"
    cat > "$dosya" << 'SABLON_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Şablon Script
set -euo pipefail
DEBUG=false
LOG_FILE="${HOME}/script.log"
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
hata()  { echo "HATA: $*" >&2; exit 1; }
basari(){ echo "OK: $*"; }
main() {
    log "Başladı"
    # === KODUNUZ BURAYA ===
    log "Bitti"; basari "Tamamlandı."
}
main "$@"
SABLON_EOF
    chmod +x "$dosya" && _basari "Şablon: $dosya" || _hata "Başarısız."
    _onay "Düzenle?" && ${EDITOR:-nano} "$dosya"
    _log "BILGI" "Script şablon: $dosya"
}

# ─── EKSİK SİSTEM ────────────────────────────────────────────
galaxy_optimizasyon() {
    _baslik "$MOR" "🚀 GALAXY A34 5G OPTİMİZASYON"
    _galaxy_kontrol && _basari "Galaxy A34 5G tespit edildi!" || _uyari "A34 tespit edilemedi, devam ediliyor..."
    echo ""
    echo -e "${BEYAZ}=== CPU ===${NC}"
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]; then
        echo -e "${BEYAZ}Governor'lar:${NC} $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)"
        echo -e "${BEYAZ}Mevcut:${NC}       $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
        echo -n -e "${YESIL}Yeni governor (boş=geç): ${NC}"; read -r gov < /dev/tty
        [ -n "$gov" ] && echo "$gov" | tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null \
            && _basari "Governor: $gov" || _uyari "Root gerekebilir."
    else
        _bilgi "CPU frekans bilgisi alınamadı."
    fi
    echo ""
    echo -e "${BEYAZ}=== Bellek ===${NC}"; free -h 2>/dev/null
    echo ""
    echo -e "${BEYAZ}=== Pil ===${NC}"
    command -v termux-battery-status &>/dev/null && \
        termux-battery-status 2>/dev/null | grep -E "percentage|status|plugged" || \
        _bilgi "termux-api yükleyin: pkg install termux-api"
    _log "BILGI" "Galaxy optimizasyon"; _bekle
}

performans_testi() {
    _baslik "$TURKUAZ" "⚡ PERFORMANS TESTİ"
    local s e f
    echo -e "${BEYAZ}CPU döngü (1000x):${NC}"
    s=$(date +%s%N 2>/dev/null || echo 0)
    for i in {1..1000}; do echo $i >/dev/null; done
    e=$(date +%s%N 2>/dev/null || echo 0)
    echo -e "  ${YESIL}$(( (e-s)/1000000 ))ms${NC}"
    echo -e "${BEYAZ}Dosya tarama (3 seviye):${NC}"
    s=$(date +%s%N 2>/dev/null || echo 0)
    find ~ -maxdepth 3 -name "*.sh" 2>/dev/null | wc -l >/dev/null
    e=$(date +%s%N 2>/dev/null || echo 0)
    echo -e "  ${YESIL}$(( (e-s)/1000000 ))ms${NC}"
    echo -e "${BEYAZ}Bellek okuma:${NC}"
    s=$(date +%s%N 2>/dev/null || echo 0); cat /proc/meminfo >/dev/null; e=$(date +%s%N 2>/dev/null || echo 0)
    echo -e "  ${YESIL}$(( (e-s)/1000000 ))ms${NC}"
    echo ""
    _basari "Test tamamlandı."
    _log "BILGI" "Performans testi"; _bekle
}

isil_kontrol() {
    _baslik "$TURKUAZ" "🌡️ ISIL KONTROL"
    local bulunan=0
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        [ -f "$zone" ] || continue
        local temp; temp=$(cat "$zone" 2>/dev/null)
        [ -z "$temp" ] && continue
        local celsius; celsius=$(awk "BEGIN{printf \"%.1f\",$temp/1000}")
        local zn; zn=$(basename "$(dirname "$zone")")
        printf "  ${BEYAZ}%-25s${NC} %s°C\n" "$zn:" "$celsius"
        awk "BEGIN{exit !($celsius>55)}" && _uyari "Sıcak: $celsius°C"
        ((bulunan++))
    done
    [ $bulunan -eq 0 ] && _bilgi "Sıcaklık sensörü bulunamadı."
    _log "BILGI" "Isıl kontrol"; _bekle
}

servis_listele() {
    _bilgi "Termux servisleri:"
    if [ -d "$PREFIX/var/service" ]; then
        ls "$PREFIX/var/service" 2>/dev/null | while read -r s; do
            local d; d=$(sv status "$s" 2>/dev/null | awk '{print $1}' || echo "?")
            printf "  ${BEYAZ}%-20s${NC} %s\n" "$s" "$d"
        done
    else
        _bilgi "Servis dizini yok. (pkg install runit)"
    fi
}

servis_baslat() {
    echo -n -e "${YESIL}Servis: ${NC}"; read -r s < /dev/tty
    [ -d "$PREFIX/var/service/$s" ] && sv up "$s" 2>&1 && _basari "Başlatıldı: $s" || _hata "Başarısız."
}

servis_durdur() {
    echo -n -e "${YESIL}Servis: ${NC}"; read -r s < /dev/tty
    [ -d "$PREFIX/var/service/$s" ] && sv down "$s" 2>&1 && _basari "Durduruldu: $s" || _hata "Başarısız."
}

servis_yeniden_baslat() {
    echo -n -e "${YESIL}Servis: ${NC}"; read -r s < /dev/tty
    [ -d "$PREFIX/var/service/$s" ] && sv restart "$s" 2>&1 && _basari "Yeniden başlatıldı: $s" || _hata "Başarısız."
}

kullanici_listele() {
    cut -d: -f1 /etc/passwd 2>/dev/null | cat -n
}

oturum_bilgi() {
    w 2>/dev/null || who 2>/dev/null || echo "Oturum bilgisi alınamadı."
    echo ""; echo -e "${BEYAZ}Son oturumlar:${NC}"
    last 2>/dev/null | head -10 || echo "Kayıt yok."
}

hostname_goster() {
    echo -e "${BEYAZ}Hostname:${NC} $(hostname 2>/dev/null)"
    echo -e "${BEYAZ}Domain:${NC}   $(dnsdomainname 2>/dev/null || echo 'yok')"
}

tarih_saat_ayarla() {
    echo -e "${BEYAZ}Şu anki:${NC} $(date)"
    echo -n -e "${YESIL}Yeni tarih (YYYY-MM-DD SS:DD): ${NC}"; read -r yeni < /dev/tty
    [ -n "$yeni" ] && date -s "$yeni" 2>&1 && _basari "Ayarlandı." || _hata "Başarısız. (Root gerekebilir)"
}

sistem_log() {
    [ -f "$LOG_DOSYA" ] && tail -50 "$LOG_DOSYA" 2>/dev/null | less -R || _bilgi "Log dosyası henüz yok."
}

# ─── EKSİK YEDEK ─────────────────────────────────────────────
yedek_karsilastir() {
    _bilgi "Mevcut yedekler:"; ls "$YEDEK_KOKU" 2>/dev/null | cat -n; echo ""
    echo -n "Yedek 1 adı: "; read -r y1 < /dev/tty
    echo -n "Yedek 2 adı: "; read -r y2 < /dev/tty
    diff -qr "$YEDEK_KOKU/$y1" "$YEDEK_KOKU/$y2" 2>/dev/null | less -R || _hata "Karşılaştırma başarısız."
    _log "BILGI" "Yedek karşılaştırma: $y1 vs $y2"
}

yedek_boyut() {
    _bilgi "Yedek boyutları:"
    du -sh "$YEDEK_KOKU"/* 2>/dev/null | sort -hr | while read -r b f; do
        printf "  ${BEYAZ}%-10s${NC} %s\n" "$b" "$(basename "$f")"
    done
    echo -e "${BEYAZ}Toplam:${NC} $(du -sh "$YEDEK_KOKU" 2>/dev/null | cut -f1)"
    _log "BILGI" "Yedek boyut analizi"
}

# ─── EKSİK ANDROİD ───────────────────────────────────────────
video_cek() {
    _api_kontrol || return 1
    local h; h=$([ -d ~/storage/movies ] && echo ~/storage/movies/termux_$(date +%Y%m%d_%H%M%S).mp4 || echo "$HOME/video_$(date +%Y%m%d_%H%M%S).mp4")
    echo -n -e "${YESIL}Süre (saniye) [5]: ${NC}"; read -r sure < /dev/tty; sure="${sure:-5}"
    _bilgi "Video çekiliyor (${sure}s)..."
    termux-camera-record -c 0 --limit "$sure" "$h" 2>/dev/null
    [ -f "$h" ] && _basari "Kaydedildi: $h" || _hata "Çekilemedi."
    _log "BILGI" "Video: $h"
}

sms_inbox() {
    _api_kontrol || return 1
    _bilgi "Gelen SMS'ler:"
    termux-sms-list 2>/dev/null | \
        { command -v jq &>/dev/null && jq -r '.[] | "[\(.number)] \(.body)"' || cat; } | \
        head -20 || _hata "SMS listesi alınamadı."
    _log "BILGI" "SMS inbox"
}

telefon_ara() {
    _api_kontrol || return 1
    echo -n -e "${YESIL}Numara: ${NC}"; read -r numara < /dev/tty
    [ -z "$numara" ] && { _hata "Numara boş!"; return 1; }
    _onay "$numara aransın mı?" || return 0
    termux-telephony-call "$numara" 2>/dev/null && _basari "Aranıyor..." || _hata "Başarısız."
    _log "GUVENLIK" "Telefon araması: $numara"
}

cevresel_isik() {
    _api_kontrol || return 1
    _bilgi "Çevresel ışık sensörü:"
    termux-sensor -s "Light" -n 1 2>/dev/null | \
        { command -v jq &>/dev/null && jq . || cat; } || \
        _hata "Işık sensörü yok veya termux-api çalışmıyor."
    _log "BILGI" "Işık sensörü"
}

wifi_bilgisi() {
    _api_kontrol || return 1
    _bilgi "Wi-Fi bilgisi:"
    termux-wifi-connectioninfo 2>/dev/null | \
        { command -v jq &>/dev/null && jq . || cat; } || \
        termux-wifi-scaninfo 2>/dev/null | \
        { command -v jq &>/dev/null && jq '.[0:5]' || head -20; } || \
        _hata "Wi-Fi bilgisi alınamadı."
    _log "BILGI" "Wi-Fi bilgisi"
}

galaxy_ozel() {
    _baslik "$MOR" "📱 GALAXY A34 5G ÖZEL"
    _galaxy_kontrol && _basari "Galaxy A34 5G tespit edildi!" || _uyari "Tespit edilemedi."
    echo ""
    echo -e "${BEYAZ}Ekran parlaklığı:${NC} $(settings get system screen_brightness 2>/dev/null || echo 'N/A')"
    echo -e "${BEYAZ}Otomatik parlaklık:${NC} $(settings get system screen_brightness_mode 2>/dev/null || echo 'N/A')"
    echo -e "${BEYAZ}CPU frekansı:${NC} $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | awk '{printf "%d MHz",$1/1000}' || echo 'N/A')"
    echo ""
    echo -e "${BEYAZ}Pil:${NC}"
    command -v termux-battery-status &>/dev/null && termux-battery-status 2>/dev/null | grep -E "percentage|status" || echo "  termux-api gerekli"
    _log "BILGI" "Galaxy özel"; _bekle
}

# ─── EKSİK MERKEZ ALT MENÜ ───────────────────────────────────
modul_script_merkez_ek() {
    while true; do
        _baslik "$SARI" "⚙️  GELİŞMİŞ SCRIPT İŞLEMLERİ"
        echo -e "  ${BEYAZ}[1]${NC}  Script kategorisi ekle"
        echo -e "  ${BEYAZ}[2]${NC}  Kategorileri listele"
        echo -e "  ${BEYAZ}[3]${NC}  Gelişmiş şablon oluştur"
        echo -e "  ${BEYAZ}[0]${NC}  Geri dön"
        echo ""
        echo -n -e "${YESIL}Seçim [0-3]: ${NC}"; read -r s < /dev/tty
        case $s in
            1) script_kategori_ekle; _bekle ;;
            2) script_kategori_liste; _bekle ;;
            3) _script_sablon_olustur; _bekle ;;
            0) return 0 ;;
            *) _hata "Geçersiz!"; sleep 1 ;;
        esac
    done
}

# ============================================================
# CLI MODU — TÜM KOMUTLAR (tüm fonksiyonlar tanımlandıktan sonra)
# ============================================================

_cli_main() {
    case "$1" in
        # Yardım & Menü
        yardim|--help|-h) modul_yardim; exit 0 ;;
        menu|ana-menu)    ana_menu; exit 0 ;;

        # Paket (18 komut)
        paket-list)          paket_listele ;;
        paket-sayi)          paket_sayisi ;;
        paket-guncelle)      paket_guncelle_tek "$2" ;;
        paket-guncelle-tum)  paket_guncelle_tumu ;;
        paket-ara)           paket_ara "$2" ;;
        paket-kur)           paket_kur "$2" ;;
        paket-kaldir)        paket_kaldir "$2" ;;
        pip-list)            pip_listele ;;
        pip-kur)             pip_kur "$2" ;;
        pip-kaldir)          pip_kaldir "$2" ;;
        pip-guncelle)        pip_guncelle "$2" ;;
        pip-cache)           pip_onbellek_temizle ;;
        npm-list)            npm_listele ;;
        npm-kur)             npm_kur "$2" ;;
        npm-kaldir)          npm_kaldir "$2" ;;
        npm-cache)           npm_onbellek_temizle ;;
        paket-yedekle)       paket_yedekle ;;
        paket-geri)          paket_geri_yukle "$2" ;;
        paket-cache)         paket_onbellek_temizle ;;
        paket-kaydet)        paket_listesi_kaydet ;;

        # Dosya (16 komut)
        dosya-list)      dizin_listele "$2" ;;
        disk)            disk_kullanimi ;;
        dizin-boyut)     dizin_boyutlari "$2" ;;
        en-buyuk)        en_buyuk_dosyalar "${2:-20}" ;;
        dosya-turu)      dosya_turu_analiz ;;
        depolama)        depolama_durumu ;;
        dosya-ara-isim)  dosya_ara_isim "$2" ;;
        dosya-ara)       dosya_ara_icerik "$2" ;;
        dosya-kopyala)   dosya_kopyala ;;
        dosya-tasi)      dosya_tasi ;;
        dosya-sil)       dosya_sil ;;
        klasor-olustur)  klasor_olustur ;;
        son-degisen)     son_degisenler "${2:-20}" ;;
        izin)            izin_duzelt ;;
        dosya-bilgi)     dosya_bilgi "$2" ;;

        # Git/Proje (17 komut)
        git-projeler)    git_projeleri_bul ;;
        git-durum)       proje_durum "$2" ;;
        git-log)
            mapfile -t p < <(find ~ -name ".git" -type d -prune 2>/dev/null | sed 's/\/.git$//')
            [ ${#p[@]} -gt 0 ] && git -C "${p[0]}" log --oneline -20 | less -R ;;
        git-pull)        git_pull_proje ;;
        git-commit)      git_commit "$2" ;;
        git-push)        git_push_sadece "$2" ;;
        git-commit-push) git_commit_push "$2" ;;
        git-branch)      git_branch_yonet "$2" ;;
        git-init)        git_init_new ;;
        git-clone)       git_clone "$2" "$3" ;;
        git-diff)
            mapfile -t p < <(find ~ -name ".git" -type d -prune 2>/dev/null | sed 's/\/.git$//')
            [ ${#p[@]} -gt 0 ] && git -C "${p[0]}" diff --color=always | less -R ;;
        node-projeler)   node_projeleri_bul ;;
        python-projeler) python_projeleri_bul ;;
        proje-boyut)     proje_boyutlari ;;
        proje-yedekle)   proje_yedekle "$2" ;;
        proje-ara)       proje_ara "$2" ;;

        # Script (20 komut)
        script-list)          script_listele ;;
        script-olustur)       script_olustur "$2" ;;
        script-ara)           script_ara "$2" ;;
        script-bilgi)         script_bilgi "$2" ;;
        script-izin)          script_izin_ver ;;
        script-duzenle)       script_duzenle "$2" ;;
        script-sil)           script_sil "$2" ;;
        script-kopyala)       script_kopyala ;;
        script-tasi)          script_tasi ;;
        script-isim)          script_isim_degistir ;;
        script-calistir)      _script_calistir_detay "$2" ;;
        script-menu)          _script_calistir_menu ;;
        script-ara-calistir)  _script_ara_calistir "$2" ;;
        script-gecmis)        _son_scriptler ;;
        script-hizli)         _hizli_script_baslat ;;
        script-favori)        _favori_scriptler ;;
        script-istatistik)    _script_istatistik ;;
        script-yedekle)       _script_yedekleme ;;

        # Alias (13 komut)
        alias-list)    alias_listele ;;
        alias-ekle)    alias_ekle "$2" "$3" ;;
        alias-kaldir)  alias_kaldir "$2" ;;
        alias-duzenle) alias_duzenle "$2" ;;
        alias-ara)     alias_ara "$2" ;;
        alias-grup)    alias_grup_olustur ;;
        alias-yedekle) alias_yedekle ;;
        alias-geri)    alias_geri_yukle ;;
        alias-disa)    alias_disa_aktar ;;
        alias-kalici)  alias_kalici_yap "$2" ;;
        alias-gecici)  alias_gecici_ekle "$2" "$3" ;;
        alias-tetik)   alias_tetikleyici_olustur ;;
        alias-uygula)  alias_tum_uygula ;;

        # Sistem (14 komut)
        sistem)       sistem_genel; _bekle ;;
        bellek)       bellek_durumu; _bekle ;;
        cpu)          cpu_bilgisi; _bekle ;;
        islemler)     islem_listele "${2:-20}" ;;
        islem-oldur)  islem_listele 20; islem_oldur; _bekle ;;
        android)      android_bilgisi; _bekle ;;
        ag)           ag_bilgisi; _bekle ;;
        termux-bilgi)
            echo "Prefix: $PREFIX"; echo "Home: $HOME"
            echo "Shell: $SHELL"; echo "Paket: $(pkg list-installed 2>/dev/null | wc -l)"
            _bekle ;;
        sistem-log)   sistem_loglari; _bekle ;;
        oturum)       kullanici_oturumlari; _bekle ;;
        donanim)      donanim_bilgisi; _bekle ;;
        disk-analiz)  disk_analiz; _bekle ;;

        # Rapor/Yedek
        rapor)          detayli_rapor_olustur ;;
        tam-yedek)      tam_yedek_al; _bekle ;;
        konfig-yedekle) konfig_yedekle; _bekle ;;
        yedek-liste)    yedekleri_listele; _bekle ;;
        yedek-temizle)  eski_yedekleri_temizle; _bekle ;;
        yedek-gonder)   yedegi_android_gonder; _bekle ;;
        yedek-oto)      otomatik_yedekleme; _bekle ;;
        yedek-geri)     yedek_geri_yukle; _bekle ;;
        script-yedek)   _script_yedekleme ;;

        # Temizlik (13 komut)
        temizlik)       tum_temizlik ;;
        gecici-temizle) gecici_temizle; _bekle ;;
        gereksiz)       gereksiz_bul; _bekle ;;
        bos-klasor)     bos_klasor_temizle; _bekle ;;
        pycache)        pycache_temizle; _bekle ;;
        node-analiz)    node_modules_analiz; _bekle ;;
        paket-cache)    paket_onbellek_temizle; _bekle ;;
        pip-cache)      pip_onbellek_temizle; _bekle ;;
        npm-cache)      npm_onbellek_temizle; _bekle ;;
        gecmis-temizle)
            _onay "Script geçmişi silinsin mi?" \
                && rm -f "$GECMIS_DOSYA" && _basari "Geçmiş temizlendi."
            _bekle ;;
        log-temizle)
            [ -f "$LOG_DOSYA" ] && { > "$LOG_DOSYA"; _basari "Log temizlendi."; }
            _bekle ;;
        disk-analiz)    disk_analiz; _bekle ;;

        # Ağ/Güvenlik (14 komut)
        acik-port)     acik_portlar; _bekle ;;
        baglanti)      ag_baglantilari; _bekle ;;
        ping)          ping_testi "$2" "${3:-4}"; _bekle ;;
        dns)           dns_sorgula "$2"; _bekle ;;
        traceroute)    traceroute_yap "$2"; _bekle ;;
        port-tara)     port_tara "$2" "$3"; _bekle ;;
        dis-ip)        dis_ip; _bekle ;;
        hiz-testi)     hiz_testi; _bekle ;;
        ssh-test)      ssh_testi; _bekle ;;
        web-kontrol)   web_site_kontrol; _bekle ;;
        ag-tara)       ag_tara; _bekle ;;
        ssl)           ssl_kontrol; _bekle ;;

        # Android (14 komut)
        pil)            pil_durumu; _bekle ;;
        bildirim)       bildirim_gonder "$2" "$3"; _bekle ;;
        titresim)       titresim_yap; _bekle ;;
        mesale)         mesale; _bekle ;;
        fotograf)       fotograf_cek; _bekle ;;
        ses-kayit)      ses_kayit; _bekle ;;
        konum)          konum_bilgisi; _bekle ;;
        kisiler)        kisiler_listele; _bekle ;;
        sms)            sms_gonder "$2" "$3"; _bekle ;;
        depolama-izin)  depolama_izni_kur; _bekle ;;
        pano)           pano_islem; _bekle ;;
        telefon)        telefon_bilgileri; _bekle ;;

        # Samsung A34 5G özel komutlar
        samsung)          samsung_a34_bilgi ;;
        performans)       sistem_performans ;;
        ag-hizi)          ag_hizi_olc; _bekle ;;
        galaxy-opt)       galaxy_optimizasyon ;;
        galaxy-ozel)      galaxy_ozel ;;
        performans-testi) performans_testi ;;
        isil-kontrol)     isil_kontrol ;;
        wifi-bilgi)       wifi_bilgisi; _bekle ;;
        sifre-uret)       guvenli_sifre_uret; _bekle ;;

        # Gelişmiş dosya komutları
        arsiv-olustur)    arsiv_olustur; _bekle ;;
        arsiv-ac)         arsiv_ac; _bekle ;;
        dosya-olustur)    dosya_olustur; _bekle ;;
        toplu-adlandir)   toplu_yeniden_adlandir; _bekle ;;
        dosya-karsilastir) dosya_karsilastir; _bekle ;;
        yinelenen-bul)    yinelenen_dosya_bul; _bekle ;;
        hash)             md5_sha_hesapla; _bekle ;;

        # Gelişmiş güvenlik
        whois)            whois_sorgula; _bekle ;;
        http-baslik)      http_baslik_kontrol; _bekle ;;
        ag-arayuz)        aktif_ag_arayuzleri; _bekle ;;

        # Gelişmiş yedekleme
        sifreli-yedek)    sifreli_yedek_al; _bekle ;;
        yedek-boyut)      yedek_boyut; _bekle ;;
        yedek-karsilastir) yedek_karsilastir; _bekle ;;

        # Gelişmiş temizlik
        buyuk-dosya-sil)  buyuk_dosya_sil; _bekle ;;
        android-cache)    android_onbellek_temizle; _bekle ;;

        # Gelişmiş paket
        paket-bilgi)      paket_bilgi; _bekle ;;
        paket-bagimli)    paket_bagimlilik; _bekle ;;
        paket-dosyalar)   paket_dosyalari; _bekle ;;
        paket-hangi)      paket_hangi_pakette; _bekle ;;
        paket-versiyon)   paket_versiyon; _bekle ;;
        paket-ara-detay)  paket_arama_detayli; _bekle ;;
        paket-istatistik) paket_istatistik; _bekle ;;
        paket-populer)    paket_populer_kur; _bekle ;;
        pip-ortam)        pip_ortam_olustur; _bekle ;;
        pip-freeze)       pip_freeze; _bekle ;;
        npm-guncelle)     npm_guncelle; _bekle ;;
        npm-versiyon)     npm_versiyon; _bekle ;;

        # Git gelişmiş
        git-log)          git_log_goster; _bekle ;;
        git-diff-goster)  git_diff_goster; _bekle ;;
        git-remote)       git_remote_listele; _bekle ;;
        git-stash)        git_stash_yonet; _bekle ;;
        git-tag)          git_tag_yonet; _bekle ;;

        # Sistem gelişmiş
        servis-list)      servis_listele; _bekle ;;
        servis-baslat)    servis_baslat; _bekle ;;
        servis-durdur)    servis_durdur; _bekle ;;
        servis-restart)   servis_yeniden_baslat; _bekle ;;
        kullanicilar)     kullanici_listele; _bekle ;;
        oturum)           oturum_bilgi; _bekle ;;
        hostname)         hostname_goster; _bekle ;;
        tarih-ayarla)     tarih_saat_ayarla; _bekle ;;
        sistem-log)       sistem_log; _bekle ;;

        # Android gelişmiş
        video-cek)        video_cek; _bekle ;;
        sms-gelen)        sms_inbox; _bekle ;;
        telefon-ara)      telefon_ara; _bekle ;;
        isik-sensor)      cevresel_isik; _bekle ;;

        # Script gelişmiş
        script-kategori-ekle)  script_kategori_ekle; _bekle ;;
        script-kategori-liste) script_kategori_liste; _bekle ;;
        script-sablon)         _script_sablon_olustur; _bekle ;;

        # Alias gelişmiş
        alias-grup-uygula)  alias_grup_uygula; _bekle ;;
        alias-import)        alias_import_bashrc; _bekle ;;

        # Bilinmeyen
        *)
            echo -e "${KIRMIZI}${BOLD}❌ Bilinmeyen komut:${NC} ${KIRMIZI}$1${NC}"
            echo -e "${GRI}Yardım için: $0 yardim${NC}"
            exit 1 ;;
    esac
}

# ============================================================
# BAŞLANGIÇ
# ============================================================
_log "BILGI" "Termux Sistem Yöneticisi v4.0 başlatıldı (PID: $$)"

# İlk kurulum kontrolü
if [ ! -d "$KONFIG_DIZINI" ]; then
    clear
    echo -e "${TURKUAZ}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${TURKUAZ}║     🎉 İLK KURULUM — DİZİNLER OLUŞTURULUYOR           ║${NC}"
    echo -e "${TURKUAZ}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    mkdir -p "$KONFIG_DIZINI" \
             "$(dirname "$GECMIS_DOSYA")" \
             "$(dirname "$FAVORI_DOSYA")" \
             "$(dirname "$LOG_DOSYA")" \
             "$YEDEK_KOKU" \
             "$ALIAS_YEDEK" 2>/dev/null
    echo -e "${YESIL}${BOLD}[OK]${NC} ${YESIL}Kurulum tamamlandı!${NC}"
    echo ""
    echo -e "${GRI}Konfig dizini: $KONFIG_DIZINI${NC}"
    echo -e "${GRI}Tüm komutlar için: $0 yardim${NC}"
    echo ""
    echo -n -e "${GRI}[ Enter'a basın... ]${NC}"
    read -r < /dev/tty
fi

# CLI veya Menü modu
if [ $# -gt 0 ] && [ "$1" != "menu" ] && [ "$1" != "0" ]; then
    _cli_main "$@"
    exit $?
else
    ana_menu
fi
