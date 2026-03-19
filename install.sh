#!/data/data/com.termux/files/usr/bin/bash
# Samsung Galaxy Termux Sistem Yönetimi v5.0 - Hızlı Kurulum
# GitHub: https://github.com/NFISS/termux-sistem-yoneticisi
# Yazar: NFISS
# Versiyon: 5.0
# Tarih: Mart 2026

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║     Samsung Galaxy - Termux Sistem Yöneticisi          ║${NC}"
echo -e "${PURPLE}║                    v5.0 KURULUM                         ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Toplam süreyi ölç
BASLANGIC=$(date +%s)

# Termux depo güncelleme
echo -e "${BLUE}[1/6]📦 Paket listesi güncelleniyor...${NC}"
pkg update -y &>/dev/null
echo -e "${GREEN}  ✓ Depo güncellendi${NC}"

# Gerekli paketler
echo -e "${BLUE}[2/6]🔧 Gerekli paketler kontrol ediliyor...${NC}"
PAKETLER="git curl"
for pkg in $PAKETLER; do
    if ! command -v $pkg &>/dev/null; then
        echo -e "${YELLOW}  📦 $pkg kuruluyor...${NC}"
        pkg install -y $pkg &>/dev/null
    fi
done
echo -e "${GREEN}  ✓ Gerekli paketler hazır${NC}"

# Script indirme
echo -e "${BLUE}[3/6]📥 Script indiriliyor...${NC}"
curl -L -o ~/termux_yonetici.sh https://raw.githubusercontent.com/NFISS/termux-sistem-yoneticisi/main/termux_v5.0.sh --progress-bar 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ İndirme başarısız!${NC}"
    exit 1
fi

BOYUT=$(du -h ~/termux_yonetici.sh | cut -f1)
echo -e "${GREEN}  ✓ Script indirildi (${BOYUT})${NC}"

# İzin verme
echo -e "${BLUE}[4/6]🔐 Çalıştırma izni veriliyor...${NC}"
chmod +x ~/termux_yonetici.sh
echo -e "${GREEN}  ✓ İzinler ayarlandı${NC}"

# Kısayollar
echo -e "${BLUE}[5/6]⚡ Kısayollar oluşturuluyor...${NC}"
echo "alias samsung='~/termux_yonetici.sh'" >> ~/.bashrc
echo "alias galaxy='~/termux_yonetici.sh'" >> ~/.bashrc
echo "alias tm='~/termux_yonetici.sh'" >> ~/.bashrc
echo "alias termux-sistem='~/termux_yonetici.sh'" >> ~/.bashrc
echo -e "${GREEN}  ✓ Kısayollar eklendi (samsung, galaxy, tm, termux-sistem)${NC}"

# Samsung cihaz kontrolü
echo -e "${BLUE}[6/6]📱 Cihaz kontrolü...${NC}"
MODEL=$(getprop ro.product.model 2>/dev/null || echo "Samsung")
if [[ "$MODEL" == *"Samsung"* ]] || [[ "$MODEL" == *"SM-"* ]]; then
    echo -e "${GREEN}  ✓ Samsung Galaxy cihaz tespit edildi!${NC}"
    
    # CPU bilgileri
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]; then
        GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
        echo -e "  └ CPU Governor: ${CYAN}$GOV${NC}"
    fi
    
    # Çekirdek sayısı
    CEKIRDEK=$(nproc 2>/dev/null || echo "8")
    echo -e "  └ Çekirdek: ${CYAN}$CEKIRDEK${NC}"
    
    # RAM
    RAM=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}')
    echo -e "  └ RAM: ${CYAN}$RAM${NC}"
else
    echo -e "${YELLOW}  ⚠ Samsung Galaxy tespit edilemedi${NC}"
    echo -e "  └ (script tüm Android cihazlarda çalışır)"
fi

# Bitiş süresi
BITIS=$(date +%s)
SURECE=$((BITIS - BASLANGIC))

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ KURULUM BAŞARIYLA TAMAMLANDI!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📊 KURULUM İSTATİSTİKLERİ:${NC}"
echo -e "  ├ Süre: ${YELLOW}${SURECE} saniye${NC}"
echo -e "  ├ Script boyutu: ${YELLOW}${BOYUT}${NC}"
echo -e "  └ Klasör: ${YELLOW}~/.termux_yonetici${NC}"
echo ""
echo -e "${YELLOW}📱 KULLANIM KOMUTLARI:${NC}"
echo -e "  ${GREEN}./termux_yonetici.sh${NC}        # Menü modu"
echo -e "  ${GREEN}samsung${NC}                       # Kısayol 1"
echo -e "  ${GREEN}galaxy${NC}                         # Kısayol 2"
echo -e "  ${GREEN}tm${NC}                            # Kısayol 3"
echo -e "  ${GREEN}./termux_yonetici.sh yardim${NC}   # Tüm komutlar"
echo ""
echo -e "${PURPLE}⭐ GitHub'da yıldız vermeyi unutma:${NC}"
echo -e "  ${CYAN}https://github.com/NFISS/termux-sistem-yoneticisi${NC}"
echo ""
echo -e "${GREEN}🚀 BAŞLAT: ./termux_yonetici.sh${NC}"
echo -e "${PURPLE}══════════════════════════════════════════════════════════${NC}"
