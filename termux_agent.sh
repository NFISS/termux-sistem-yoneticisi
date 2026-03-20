#!/data/data/com.termux/files/usr/bin/bash
# TERMUX AGENT v3.0 - Akıllı Sistem Analizi

K='\033[0;31m'; Y='\033[0;32m'; S='\033[1;33m'
M='\033[0;35m'; T='\033[0;36m'; NC='\033[0m'

sistem_analiz() {
    clear
    echo -e "${M}╔══════════════════════════════════════════╗${NC}"
    echo -e "${M}║     🤖 SİSTEM ANALİZ RAPORU             ║${NC}"
    echo -e "${M}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # RAM
    echo -e "${S}📊 BELLEK (RAM)${NC}"
    local total avail kullanim
    total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    kullanim=$(( (total - avail) * 100 / total ))
    echo "  Toplam: $((total/1024/1024)) GB"
    echo "  Kullanılan: $(( (total-avail)/1024/1024 )) GB"
    echo -n "  Durum: "
    if [ $kullanim -gt 80 ]; then
        echo -e "${K}⚠️  YÜKSEK (%$kullanim)${NC}"
    elif [ $kullanim -gt 60 ]; then
        echo -e "${S}⚡ ORTA (%$kullanim)${NC}"
    else
        echo -e "${Y}✅ NORMAL (%$kullanim)${NC}"
    fi
    echo ""

    # DİSK
    echo -e "${S}💾 DİSK${NC}"
    local disk_yuzde
    disk_yuzde=$(df -h ~ | awk 'NR==2{print $5}' | tr -d '%')
    echo "  $(df -h ~ | awk 'NR==2{print "Toplam:"$2" Kullanılan:"$3" Boş:"$4}')"
    echo -n "  Durum: "
    if [ "$disk_yuzde" -gt 90 ]; then
        echo -e "${K}⚠️  KRİTİK (%$disk_yuzde)${NC}"
    elif [ "$disk_yuzde" -gt 75 ]; then
        echo -e "${S}⚡ DIKKAT (%$disk_yuzde)${NC}"
    else
        echo -e "${Y}✅ NORMAL (%$disk_yuzde)${NC}"
    fi
    echo ""

    # CPU YÜK
    echo -e "${S}⚙️  CPU YÜK${NC}"
    local yuk
    yuk=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
    echo "  Yük ortalaması: $yuk"
    echo "  Çekirdek: $(nproc)"
    echo "  Uptime: $(uptime -p)"
    echo ""

    # SİSTEM
    echo -e "${S}📱 SİSTEM${NC}"
    echo "  Android: $(getprop ro.build.version.release 2>/dev/null)"
    echo "  Kernel: $(uname -r | cut -d- -f1)"
    echo "  Cihaz: $(getprop ro.product.model 2>/dev/null)"
    echo ""

    # PAKETLER
    echo -e "${S}📦 PAKETLER${NC}"
    local paket_say
    paket_say=$(pkg list-installed 2>/dev/null | wc -l)
    echo "  Yüklü: $paket_say paket"
    local guncelle
    guncelle=$(pkg list-upgradable 2>/dev/null | wc -l)
    echo "  Güncellenebilir: $guncelle paket"
    echo ""

    # SCRİPT
    echo -e "${S}📜 SCRİPTLER${NC}"
    local script_say
    script_say=$(find ~ -name "*.sh" -type f 2>/dev/null | wc -l)
    echo "  Toplam script: $script_say"
    echo ""

    # ÖNERİLER
    echo -e "${M}💡 ÖNERİLER${NC}"
    [ $kullanim -gt 80 ] && echo -e "  ${K}→ RAM dolmak üzere! Gereksiz uygulamaları kapat${NC}"
    [ "$disk_yuzde" -gt 75 ] && echo -e "  ${S}→ Disk %$disk_yuzde dolu, temizlik önerilir${NC}"
    [ "$guncelle" -gt 0 ] && echo -e "  ${Y}→ $guncelle paket güncellenebilir: pkg upgrade${NC}"
    [ $kullanim -le 60 ] && [ "$disk_yuzde" -le 75 ] && \
        echo -e "  ${Y}→ Sistem sağlıklı görünüyor ✅${NC}"
    echo ""

    # RAPORU KAYDET
    local rapor=~/agent_rapor_$(date +%Y%m%d_%H%M%S).txt
    {
        echo "TERMUX SİSTEM RAPORU - $(date)"
        echo "================================"
        echo "RAM Kullanım: %$kullanim"
        echo "Disk Kullanım: %$disk_yuzde"
        echo "CPU Yük: $yuk"
        echo "Paket: $paket_say yüklü, $guncelle güncellenebilir"
        echo "Script: $script_say"
    } > "$rapor"
    echo -e "  ${Y}✅ Rapor: $rapor${NC}"
}

disk_analiz() {
    clear
    echo -e "${M}╔══════════════════════════════════════════╗${NC}"
    echo -e "${M}║     💾 DİSK ANALİZİ                     ║${NC}"
    echo -e "${M}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${S}En büyük dizinler:${NC}"
    du -sh ~/* 2>/dev/null | sort -hr | head -10 | while read -r boyut dizin; do
        printf "  ${Y}%-8s${NC} %s\n" "$boyut" "$dizin"
    done
    echo ""
    echo -e "${S}Temizlenebilecekler:${NC}"
    find ~ -name "*.log" -size +1M 2>/dev/null | while read -r f; do
        echo -e "  ${K}Log:${NC} $f ($(du -h "$f" | cut -f1))"
    done
    find ~ -name "__pycache__" -type d 2>/dev/null | while read -r d; do
        echo -e "  ${K}Cache:${NC} $d"
    done
    find ~ -name "*.tmp" 2>/dev/null | while read -r f; do
        echo -e "  ${K}Temp:${NC} $f"
    done
    echo ""
}

en_buyuk_dosyalar() {
    clear
    echo -e "${M}╔══════════════════════════════════════════╗${NC}"
    echo -e "${M}║     📁 EN BÜYÜK DOSYALAR                ║${NC}"
    echo -e "${M}╚══════════════════════════════════════════╝${NC}"
    echo ""
    find ~ -type f -exec du -h {} + 2>/dev/null | sort -hr | head -15 | \
    while read -r boyut dosya; do
        printf "  ${Y}%-8s${NC} %s\n" "$boyut" "$dosya"
    done
    echo ""
}

git_analiz() {
    clear
    echo -e "${M}╔══════════════════════════════════════════╗${NC}"
    echo -e "${M}║     🚀 GİT PROJELERİ                    ║${NC}"
    echo -e "${M}╚══════════════════════════════════════════╝${NC}"
    echo ""
    find ~ -name ".git" -type d 2>/dev/null | while read -r gitdir; do
        local proje
        proje=$(dirname "$gitdir")
        local branch
        branch=$(git -C "$proje" branch --show-current 2>/dev/null)
        local degisiklik
        degisiklik=$(git -C "$proje" status -s 2>/dev/null | wc -l)
        local son_commit
        son_commit=$(git -C "$proje" log -1 --oneline 2>/dev/null)
        echo -e "  ${Y}$(basename "$proje")${NC}"
        echo "    Branch: $branch"
        echo "    Değişiklik: $degisiklik"
        echo "    Son commit: $son_commit"
        echo ""
    done
}

paket_analiz() {
    clear
    echo -e "${M}╔══════════════════════════════════════════╗${NC}"
    echo -e "${M}║     📦 PAKET ANALİZİ                    ║${NC}"
    echo -e "${M}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${S}Yüklü paket sayısı:${NC} $(pkg list-installed 2>/dev/null | wc -l)"
    echo ""
    echo -e "${S}Güncellenebilir paketler:${NC}"
    pkg list-upgradable 2>/dev/null | head -10 | while read -r p; do
        echo "  → $p"
    done
    echo ""
    echo -e "${S}En son yüklenen 10 paket:${NC}"
    pkg list-installed 2>/dev/null | tail -10 | while read -r p; do
        echo "  $p"
    done
    echo ""
}

ana_menu() {
    while true; do
        clear
        echo -e "${M}╔══════════════════════════════════════════╗${NC}"
        echo -e "${M}║     🤖 TERMUX AGENT v3.0                ║${NC}"
        echo -e "${M}║     Akıllı Sistem Yöneticisi            ║${NC}"
        echo -e "${M}╚══════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${S}[1]${NC} 📊 Sistem analiz raporu"
        echo -e "  ${S}[2]${NC} 💾 Disk analizi"
        echo -e "  ${S}[3]${NC} 📁 En büyük dosyalar"
        echo -e "  ${S}[4]${NC} 🚀 Git projeleri"
        echo -e "  ${S}[5]${NC} 📦 Paket analizi"
        echo -e "  ${S}[0]${NC} Çıkış"
        echo ""
        echo -n -e "${Y}Seçim: ${NC}"
        read -r s < /dev/tty

        case $s in
            1) sistem_analiz; ;;
            2) disk_analiz ;;
            3) en_buyuk_dosyalar ;;
            4) git_analiz ;;
            5) paket_analiz ;;
            0) exit 0 ;;
            *) echo -e "${K}Geçersiz!${NC}"; sleep 1; continue ;;
        esac

        echo -n -e "\n${T}[ Enter'a bas ]${NC}"
        read -r < /dev/tty
    done
}

ana_menu
