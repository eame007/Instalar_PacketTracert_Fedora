# Cisco Packet Tracer Installer para Fedora

Un script interactivo en Bash para instalar de manera limpia y nativa Cisco Packet Tracer en Fedora Linux (y derivadas), utilizando el paquete `.deb` oficial.

## Características

- Extrae y convierte el paquete `.deb` sin usar dpkg ni alien.
- Instala automáticamente las dependencias gráficas de Qt5 necesarias en Fedora.
- Selector dinámico de íconos (permite usar una imagen personalizada).
- Integra Packet Tracer con tu entorno de escritorio GNOME/Wayland.
- Incluye un desinstalador limpio que pregunta si deseas conservar o borrar tus datos de usuario.

## Requisitos

1. Descargar el instalador de **Ubuntu 64-bit (.deb)** desde [NetAcad](https://www.netacad.com/resources/lab-downloads?courseLang=es-XL).
2. Tener el archivo `.deb` guardado en tu computadora en la misma carpeta que este script.

## Instalación

1. Descarga el script `install_pt.sh` o clona este repositorio.
2. **(Opcional - Ícono personalizado):** Si no quieres el ícono genérico, busca la imagen que deseas usar (`.png`, `.jpg`, `.svg` o `.webp`) y **guárdala exactamente en la misma carpeta** donde tienes el script `install_pt.sh`.
3. Abre una terminal en esa carpeta y dale permisos de ejecución al script:
   ```bash
   chmod +x install_pt.sh
4. Ejecuta el script
   **./install_pt.sh**
5. Seguimos la instrucciones en texto que nos va dando la Terminal 
