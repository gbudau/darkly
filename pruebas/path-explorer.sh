#!/bin/bash

# Comprobación de argumentos
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <url_base> <url_diccionario>"
    echo "Ejemplo: $0 https://example.com https://miweb.com/paths.txt"
    exit 1
fi

URL_BASE="$1"
DICT_URL="$2"
DICT_FILE="/tmp/tmp_paths.txt"

# Descargamos el diccionario
echo "Descargando diccionario desde: $DICT_URL ..."
curl -s -o "$DICT_FILE" "$DICT_URL"

if [ $? -ne 0 ] || [ ! -s "$DICT_FILE" ]; then
    echo "Error al descargar el diccionario."
    exit 1
fi

echo "Diccionario descargado. Comenzando exploración..."
echo "----------------------------------------------------"

# Exploramos las rutas
echo "" > found_paths.txt  # Limpiamos archivo anterior

LINE_NUMBER=0
while IFS= read -r path || [ -n "$path" ]; do
    ((LINE_NUMBER++))
    
    # Limpiar espacios al principio y fin
    clean_path=$(echo "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Saltar líneas vacías
    if [ -z "$clean_path" ]; then
        echo "[Línea $LINE_NUMBER] Línea vacía, se omite."
        continue
    fi

    # Asegurar que comience con "/"
    [[ "$clean_path" != /* ]] && clean_path="/$clean_path"

    full_url="${URL_BASE}${clean_path}"

    echo "[Línea $LINE_NUMBER] Probando URL: $full_url"

    # Intentamos la solicitud con curl y capturamos errores
    html=$(curl -s "$full_url" 2>curl_error.log)
    curl_exit=$?

    if [ $curl_exit -ne 0 ]; then
        echo "[Línea $LINE_NUMBER] ❌ Error curl ($curl_exit) al acceder: $full_url"
        echo "  > Detalles: $(<curl_error.log)"
        continue
    fi

    # Comprobamos si es un 404
    if echo "$html" | grep -qi "<title>404"; then
        echo "[Línea $LINE_NUMBER] ❌ No encontrada (404)"
    else
        echo "[Línea $LINE_NUMBER] ✅ Ruta válida encontrada: $full_url"
        echo "$full_url" >> found_paths.txt
    fi
done < "$DICT_FILE"

echo "----------------------------------------------------"
echo "Rutas válidas guardadas en: found_paths.txt"
