#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# 1. SETUP VARIABLES
# ==========================================
# Pengaturan path
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.local/share/icons/Vara"

# ==========================================
# STEP 1: PERIKSA & BUAT DIREKTORI
# ==========================================
echo "=> Memeriksa instalasi icon theme Vara..."

if [[ -d "$TARGET_DIR" ]]; then
    echo "=> Direktori $TARGET_DIR sudah ada. Melanjutkan ke Step 2 (Generate Icons)..."
else
    echo "=> Direktori Vara belum ada. Membuat struktur direktori..."
    
    # Membuat dir tree dengan brace expansion (lebih efisien)
    mkdir -p "$TARGET_DIR/scalable/"{actions,apps,categories,devices,emblems,emotes,mimetypes,places,status}
    mkdir -p "$TARGET_DIR/symbolic/"{actions,apps,categories,devices,emblems,emotes,mimetypes,places,status}
    
    echo "=> Menyalin index.theme..."
    if [[ -f "$PROJECT_DIR/index.theme" ]]; then
        cp "$PROJECT_DIR/index.theme" "$TARGET_DIR/"
    else
        echo "Peringatan: File index.theme tidak ditemukan di root project!"
    fi
    
    echo "=> Menyalin direktori symbolic..."
    if [[ -d "$PROJECT_DIR/icons/symbolic" ]]; then
        # Menggunakan /. di akhir source untuk copy & merge seluruh isi folder ke target
        cp -a "$PROJECT_DIR/icons/symbolic/." "$TARGET_DIR/symbolic/"
    fi
    
    echo "=> Struktur direktori berhasil dibuat."
fi

# ==========================================
# STEP 2: GENERATE ICONS (COLOR REPLACEMENT)
# ==========================================
echo -e "\n=========================================="
echo "          GENERATE SCALABLE ICONS         "
echo "=========================================="
echo "Keterangan: Sebaiknya warna Primary lebih pekat/gelap dari warna Secondary."
echo "Contoh input: #1e1e2e, #89b4fa, atau nama warna seperti black, blue."

# Meminta input warna dari user
read -p "Masukkan warna Primary   : " COLOR_PRIMARY
read -p "Masukkan warna Secondary : " COLOR_SECONDARY

# Validasi sederhana: pastikan input tidak kosong
if [[ -z "$COLOR_PRIMARY" || -z "$COLOR_SECONDARY" ]]; then
    echo "Error: Warna Primary dan Secondary tidak boleh kosong!"
    exit 1
fi

SRC_PLACES="$PROJECT_DIR/icons/scalable/places"
DEST_PLACES="$TARGET_DIR/scalable/places"

# Memastikan folder target places tersedia (jaga-jaga jika folder target dibuat manual sebelumnya)
mkdir -p "$DEST_PLACES"

if [[ ! -d "$SRC_PLACES" ]]; then
    echo "Error: Folder sumber icon ($SRC_PLACES) tidak ditemukan!"
    exit 1
fi

echo -e "\n=> Mulai generate warna untuk icon SVG..."

# Menghitung jumlah file untuk log sederhana
count=0

# Loop untuk memproses setiap file .svg di dalam folder places
for svg_file in "$SRC_PLACES"/*.svg; do
    # Skip jika tidak ada file svg yang ditemukan (glob failed)
    [[ -e "$svg_file" ]] || continue
    
    filename=$(basename "$svg_file")
    
    # Mengganti fill="primary" dan fill="secondary" menggunakan sed
    # Menggunakan delimiter | pada sed agar aman jika input warna berupa format rgb/rgba
    sed -e "s|fill=\"primary\"|fill=\"${COLOR_PRIMARY}\"|g" \
        -e "s|fill=\"secondary\"|fill=\"${COLOR_SECONDARY}\"|g" \
        "$svg_file" > "$DEST_PLACES/$filename"
        
    count=$((count + 1))
done

echo "=> Berhasil meng-generate $count icons ke $DEST_PLACES."

# ==========================================
# STEP 3: UPDATE ICON CACHE
# ==========================================
echo -e "\n=> Memperbarui icon cache pada sistem..."
if command -v gtk-update-icon-cache &> /dev/null; then
    # -f: force, -q: quiet, -t: don't check theme index
    gtk-update-icon-cache -f -q -t "$TARGET_DIR"
    echo "=> Icon cache berhasil diperbarui. Perubahan seharusnya sudah langsung aktif."
else
    echo "=> Peringatan: 'gtk-update-icon-cache' tidak ditemukan."
    echo "=> Perubahan mungkin baru terlihat setelah kamu restart file manager / Niri WM."
fi

echo -e "\nSelesai! 🎉"