#!/bin/bash
# Convert, resize, and crop all images to 800x800 square JPEGs
# Handles .JPG, .HEIC, .jpeg, .png — outputs as {id}.jpg
# Run this after adding new photos: ./resize.sh

DIR="$(cd "$(dirname "$0")" && pwd)/images"

echo "Processing images in: $DIR"
echo ""

# First pass: convert non-.jpg files to .jpg
for f in "$DIR"/*.JPG "$DIR"/*.HEIC "$DIR"/*.jpeg "$DIR"/*.png "$DIR"/*.PNG; do
    [ -f "$f" ] || continue
    filename=$(basename "$f")
    # Extract the number (strip leading zeros)
    num=$(echo "$filename" | sed 's/^0*//' | sed 's/\..*//')
    target="$DIR/${num}.jpg"

    echo "  CONVERTING $filename → ${num}.jpg"
    sips -s format jpeg "$f" --out "$target" >/dev/null 2>&1

    # Remove original if conversion succeeded and it's a different file
    if [ -f "$target" ] && [ "$f" != "$target" ]; then
        rm "$f"
    fi
done

echo ""

# Second pass: resize all .jpg to 800x800 square
for f in "$DIR"/*.jpg; do
    [ -f "$f" ] || continue
    filename=$(basename "$f")

    width=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/{print $2}')
    height=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/{print $2}')

    if [ "$width" -eq 800 ] && [ "$height" -eq 800 ]; then
        echo "  SKIP $filename (already 800x800)"
        continue
    fi

    echo "  RESIZING $filename (${width}x${height})"

    # Resize so the shorter side is 800px
    if [ "$width" -gt "$height" ]; then
        sips --resampleHeight 800 "$f" --out "$f" >/dev/null 2>&1
    elif [ "$height" -gt "$width" ]; then
        sips --resampleWidth 800 "$f" --out "$f" >/dev/null 2>&1
    else
        sips -Z 800 "$f" --out "$f" >/dev/null 2>&1
    fi

    # Re-read dimensions after resize
    width=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/{print $2}')
    height=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/{print $2}')

    # Center crop to 800x800
    if [ "$width" -ne 800 ] || [ "$height" -ne 800 ]; then
        sips --cropToHeightWidth 800 800 "$f" --out "$f" >/dev/null 2>&1
    fi

    size=$(ls -lh "$f" | awk '{print $5}')
    echo "    → 800x800, $size"
done

echo ""
echo "Done! All images are now 800x800 .jpg squares."
