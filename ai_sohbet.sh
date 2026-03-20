#!/data/data/com.termux/files/usr/bin/bash

MODEL=~/ai-modeller/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf
SISTEM="Sen Turkce konusan yardimci bir asistansin. Sadece Turkce cevap ver. Kisa ve net cevaplar ver."

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     🤖 TERMUX AI ASISTAN             ║"
echo "║     Qwen2.5 - Turkce Offline AI      ║"
echo "║     Çıkmak için: exit yaz            ║"
echo "╚══════════════════════════════════════╝"
echo ""

GECMIS="$SISTEM"

while true; do
    echo -n "Sen: "
    read -r SORU

    [ "$SORU" = "exit" ] && { echo "Görüşürüz!"; break; }
    [ -z "$SORU" ] && continue

    GECMIS="$GECMIS Kullanici: $SORU Asistan:"

    echo -n "AI:  "
    CEVAP=$(llama-cli -m "$MODEL" -p "$GECMIS" -n 150 --no-display-prompt 2>/dev/null)
    echo "$CEVAP"
    echo ""

    GECMIS="$GECMIS $CEVAP"
done
