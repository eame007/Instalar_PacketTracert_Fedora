#!/bin/bash

set -euo pipefail
Red="\033[0;31m"
Bold="\033[1m"
Color_Off="\033[0m"
Cyan="\033[0;36m"
Green="\033[0;32m"
Yellow="\033[1;33m"
user_name="${SUDO_USER:-$(who | cut -d ' ' -f 1 | head -1)}"
installer_search_path="/home/$user_name"
# Detecta la carpeta exacta donde está guardado este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

USAGE_MESSAGE="Uso: $0 [OPCIONES]... [DIRECTORIO]...
Instala Cisco Packet Tracer en Fedora Linux utilizando el .deb de Cisco.

 -d, --directory      Directorio donde se encuentra el instalador
 -h, --help           Muestra este mensaje de ayuda
 --uninstall          Desinstala Cisco Packet Tracer
"

install () {
  selected_installer=$(realpath "$selected_installer")

  echo -e "${Cyan}${Bold}Limpiando instalaciones previas...${Color_Off}"
  sudo rm -rf /opt/pt
  sudo rm -f /usr/local/bin/packettracer
  sudo rm -f /usr/share/applications/cisco-pt*.desktop
  sudo rm -f /usr/share/pixmaps/cisco-pt.*

  echo -e "${Cyan}${Bold}Instalando dependencias necesarias para Fedora...${Color_Off}"
  sudo dnf -y install binutils fuse fuse-libs qt5-qtbase qt5-qtmultimedia qt5-qtsvg qt5-qtnetworkauth qt5-qtwebengine libX11 alsa-lib > /dev/null
  
  echo -e "${Cyan}${Bold}Extrayendo archivos de $selected_installer...${Color_Off}"
  mkdir -p packettracer_temp
  cd packettracer_temp
  
  ar -x "$selected_installer"
  tar -xf data.tar.*
  
  echo -e "${Cyan}${Bold}Copiando binarios al sistema...${Color_Off}"
  sudo cp -r opt/pt /opt/
  
  echo -e "${Cyan}${Bold}Configurando ícono...${Color_Off}"
  ICON_FILE="cisco-pt.png"
  
  # Buscar imágenes en el directorio del script
  shopt -s nullglob
  available_icons=("$SCRIPT_DIR"/*.{png,webp,jpg,jpeg,svg})
  shopt -u nullglob

  if [ ${#available_icons[@]} -gt 0 ]; then
      echo -e "\n${Yellow}Se encontraron las siguientes imágenes en la carpeta del script:${Color_Off}"
      # Agregamos la opción para extraer por defecto al final de la lista
      opciones=("${available_icons[@]}" "No usar imagen personalizada (Extraer del instalador)")
      
      PS3="Selecciona el ícono que deseas aplicar (ingresa el número): "
      select opt_img in "${opciones[@]}"; do
          if [ "$opt_img" == "No usar imagen personalizada (Extraer del instalador)" ]; then
              echo "Se intentará extraer el ícono del paquete .deb..."
              break
          elif [ -n "$opt_img" ] && [ -f "$opt_img" ]; then
              ext="${opt_img##*.}"
              ICON_FILE="cisco-pt.$ext"
              sudo cp "$opt_img" "/usr/share/pixmaps/$ICON_FILE"
              echo -e "${Green}Ícono personalizado configurado correctamente.${Color_Off}"
              break
          else
              echo "Selección inválida."
          fi
      done
  else
      echo "No se detectaron imágenes personalizadas. Intentando extraer del paquete..."
  fi
  
  # Si no se configuró un ícono personalizado, extraemos el original
  if [ ! -f "/usr/share/pixmaps/$ICON_FILE" ]; then
      icon_path=$(find . -type f \( -iname "cisco-pt*.png" -o -iname "packettracer*.png" -o -iname "app.png" \) 2>/dev/null | head -n 1 || true)
      if [ -n "$icon_path" ] && [ -f "$icon_path" ]; then
          sudo cp "$icon_path" /usr/share/pixmaps/cisco-pt.png
          ICON_FILE="cisco-pt.png"
      fi
  fi
  
  if [ ! -d /usr/local/bin ]; then
     sudo mkdir -p /usr/local/bin
  fi
  
  echo -e "${Cyan}${Bold}Creando lanzador optimizado para GNOME/Wayland...${Color_Off}"
  cat <<'EOF' | sudo tee /usr/local/bin/packettracer > /dev/null
#!/bin/bash
export QT_QPA_PLATFORM=xcb

if [ -f /opt/pt/packettracer.AppImage ]; then
    /opt/pt/packettracer.AppImage "$@"
else
    /opt/pt/packettracer "$@"
fi
EOF
  sudo chmod +x /usr/local/bin/packettracer

  echo -e "${Cyan}${Bold}Creando acceso directo (.desktop)...${Color_Off}"
  cat <<EOF | sudo tee /usr/share/applications/cisco-pt.desktop > /dev/null
[Desktop Entry]
Name=Cisco Packet Tracer
Comment=Simulador de redes de Cisco
Exec=/usr/local/bin/packettracer %f
Icon=/usr/share/pixmaps/$ICON_FILE
Terminal=false
Type=Application
Categories=Education;Network;
MimeType=application/x-pka;application/x-pkt;application/x-pkz;
EOF

  echo -e "${Cyan}${Bold}Actualizando base de datos del escritorio...${Color_Off}"
  sudo update-desktop-database /usr/share/applications &> /dev/null || true
  sudo update-mime-database /usr/share/mime &> /dev/null || true
  sudo gtk-update-icon-cache -t --force /usr/share/icons &> /dev/null || true
  
  cd ..
  rm -rf packettracer_temp
  
  echo -e "\n========================================================"
  echo -e "${Yellow}${Bold}VERIFICACIÓN DE LICENCIA (EULA)${Color_Off}"
  echo -e "========================================================"
  echo -e "Se verificará si necesitas aceptar la licencia.\n"
  echo -e "${Bold}Nota:${Color_Off} Si ya la aceptaste antes, el programa simplemente"
  echo -e "se abrirá (o no hará nada). Si es así, ciérralo y habrás terminado."
  echo -e "========================================================\n"
  
  read -p "Presiona ENTER para verificar la licencia..."

  sudo -u "$user_name" env DISPLAY="${DISPLAY:-:0}" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" /usr/local/bin/packettracer 2>/dev/null || true

  echo -e "\n${Green}${Bold}¡Instalación completada exitosamente!${Color_Off}"
  exit 0
}

uninstall () {
  echo -e "${Red}${Bold}Desinstalando archivos de Cisco Packet Tracer del sistema...${Color_Off}"
  sudo rm -rf /opt/pt
  sudo rm -f /usr/share/applications/cisco-pt*.desktop
  sudo rm -f /home/$user_name/.local/share/applications/cisco-pt*.desktop
  sudo rm -f /home/$user_name/.local/share/applications/CiscoPacketTracer*.desktop
  sudo rm -f /usr/share/mime/packages/cisco-p*.xml
  sudo rm -f /home/$user_name/.local/share/mime/packages/cisco-p*.xml
  sudo rm -f /usr/local/bin/packettracer
  sudo rm -f /usr/share/pixmaps/cisco-pt.*
  
  sudo update-desktop-database /usr/share/applications &> /dev/null || true
  sudo update-mime-database /usr/share/mime &> /dev/null || true
  sudo gtk-update-icon-cache -t --force /usr/share/icons &> /dev/null || true
  
  echo -e "\n${Yellow}========================================================${Color_Off}"
  read -p "¿Deseas eliminar también tus configuraciones, archivos de usuario y el estado de la licencia? (s/N): " borrar_datos
  
  if [[ "$borrar_datos" =~ ^[sS]$ ]]; then
      echo -e "${Cyan}Borrando datos de usuario...${Color_Off}"
      sudo rm -rf "/home/$user_name/.pt"
      sudo rm -rf "/home/$user_name/.cisco"
      echo -e "${Green}Datos de usuario eliminados.${Color_Off}"
  else
      echo -e "${Green}Se han conservado tus datos y configuraciones personales.${Color_Off}"
  fi
  
  echo -e "\n${Green}${Bold}Cisco Packet Tracer ha sido desinstalado.${Color_Off}"
  exit 0
}

locate_installers () {
  localized_installers=()
  selected_installer=''

  echo -e "\n${Green}${Bold}Buscando el instalador .deb en $installer_search_path...${Color_Off}\n"
  c=1
  
  while IFS= read -r -d '' installer; do
      localized_installers[$c]="$installer"
      ((c++))
  done < <(find "$installer_search_path" -type f -iname "*Packet*Tracer*.deb" -print0)

  if [[ ${#localized_installers[@]} -eq 0 ]]; then
    echo -e "${Red}${Bold}No se encontró ningún instalador de Packet Tracer en ${installer_search_path}.${Color_Off}"
    echo "Descarga el archivo .deb y colócalo en tu carpeta personal o Descargas."
    exit 1
  elif [ "${#localized_installers[@]}" -eq 1 ]; then
    selected_installer="${localized_installers[1]}"
  else
    echo -e "${Cyan}${Bold}Se encontraron varios instaladores:${Color_Off}\n"
    PS3="Selecciona el número del instalador a usar: "
    select installer in "${localized_installers[@]}"; do
      if [ -n "$installer" ]; then
        selected_installer=$installer
        break
      else
        echo "Selección inválida."
      fi
    done
  fi

  echo -e "\n${Bold}Instalador seleccionado: ${Red}${Bold}$selected_installer${Color_Off}\n"
  sleep 2
  install
}

main_menu () {
  clear
  echo -e "${Cyan}${Bold}=============================================${Color_Off}"
  echo -e "${Cyan}${Bold}   Script para Cisco Packet Tracer en Fedora ${Color_Off}"
  echo -e "${Cyan}${Bold}=============================================${Color_Off}\n"
  echo -e "Elige una opción ingresando el número correspondiente:\n"
  echo -e "  ${Green}1) Instalar / Actualizar${Color_Off} Cisco Packet Tracer"
  echo -e "  ${Red}2) Desinstalar${Color_Off} Cisco Packet Tracer"
  echo -e "  3) Salir del script\n"
  
  read -p "Opción [1-3]: " opcion

  case $opcion in
    1) locate_installers ;;
    2) uninstall ;;
    3) echo "Saliendo..."; exit 0 ;;
    *) echo -e "${Red}Opción inválida.${Color_Off}"; sleep 2; main_menu ;;
  esac
}

if [ $# -eq 0 ]; then
  main_menu
else
  case "${1:-}" in
    -h | --help)
      echo "$USAGE_MESSAGE"
      exit 0
      ;;
    -d | --directory)
      if [ -n "${2:-}" ]; then
          installer_search_path="$2"
          echo -e "Directorio de búsqueda personalizado: ${Bold}$installer_search_path${Color_Off}"
          locate_installers
      else
          echo -e "${Red}${Bold}Falta especificar el directorio.${Color_Off}"
          exit 1
      fi
      ;;
    --uninstall)
      uninstall
      ;;
    *)
      locate_installers
      ;;
  esac
fi
