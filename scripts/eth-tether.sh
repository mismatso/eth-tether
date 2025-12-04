#!/bin/bash

# ==============================================================================
# Script: eth-tether.sh
# Descripción: Comparte Internet de WiFi a Ethernet de forma efímera.
# Autor: Misael Matamoros (mismatso)
# Entorno: Debian 12+ (NetworkManager + iptables)
# ==============================================================================

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Nombre de la conexión temporal de NetworkManager
CON_NAME="RED_COMPARTIDA_ETH"

# Verificación de privilegios de root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Por favor ejecute este script como root (sudo).${NC}"
  exit 1
fi

# ==============================================================================
# FUNCIONES
# ==============================================================================

detectar_interfaces() {
    echo -e "${BLUE}[INFO] Detectando interfaces de red físicas...${NC}"
    
    # Busca interfaz inalámbrica (patrón wl*)
    WIFI_IF=$(ip -o link show | awk -F': ' '$2 ~ /^wl/ {print $2; exit}')
    
    # Busca interfaz cableada (patrón en* o eth*), excluyendo veth (virtual ethernet)
    # Prioriza interfaces que no sean USB si es posible, o toma la primera encontrada.
    ETH_IF=$(ip -o link show | awk -F': ' '$2 ~ /^(en|eth)/ && $2 !~ /^veth/ {print $2; exit}')

    if [ -z "$WIFI_IF" ]; then
        echo -e "${RED}[ERROR] No se detectó interfaz WiFi.${NC}"
        exit 1
    fi

    if [ -z "$ETH_IF" ]; then
        echo -e "${RED}[ERROR] No se detectó interfaz Ethernet.${NC}"
        exit 1
    fi

    echo -e "${GREEN}[OK] WiFi detectada: $WIFI_IF${NC}"
    echo -e "${GREEN}[OK] Ethernet detectada: $ETH_IF${NC}"
}

limpieza() {
    echo -e "\n${YELLOW}[LIMPIEZA] Restaurando configuración original...${NC}"
    
    # 1. Eliminar reglas de iptables (Silenciar errores si no existen)
    # Borramos explícitamente las reglas que insertamos al inicio
    iptables -D FORWARD -i "$ETH_IF" -o "$WIFI_IF" -j ACCEPT 2>/dev/null
    iptables -D FORWARD -i "$WIFI_IF" -o "$ETH_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null
    iptables -t nat -D POSTROUTING -o "$WIFI_IF" -j MASQUERADE 2>/dev/null

    # 2. Desactivar y borrar la conexión de NetworkManager
    if nmcli connection show "$CON_NAME" >/dev/null 2>&1; then
        nmcli connection down "$CON_NAME" >/dev/null 2>&1
        nmcli connection delete "$CON_NAME" >/dev/null 2>&1
        echo -e "${GREEN}[OK] Conexión '$CON_NAME' eliminada.${NC}"
    else
        echo -e "${BLUE}[INFO] No se encontró conexión activa para limpiar.${NC}"
    fi
}

configurar_red() {
    echo -e "${BLUE}[INFO] Configurando NetworkManager...${NC}"
    
    # Crear conexión compartida
    # ipv4.method shared levanta dnsmasq y configura NAT básico
    if nmcli con add type ethernet ifname "$ETH_IF" ipv4.method shared con-name "$CON_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}[OK] Perfil de red creado.${NC}"
    else
        echo -e "${RED}[ERROR] Fallo al crear el perfil de NetworkManager.${NC}"
        exit 1
    fi

    # Levantar la conexión
    nmcli con up "$CON_NAME" >/dev/null 2>&1
    
    # Esperar un momento para que la interfaz suba
    sleep 2
}

aplicar_reglas_firewall() {
    echo -e "${BLUE}[INFO] Aplicando reglas de iptables (Bypass de Docker)...${NC}"

    # Insertamos en la posición 1 para tener prioridad sobre Docker
    iptables -I FORWARD 1 -i "$ETH_IF" -o "$WIFI_IF" -j ACCEPT
    iptables -I FORWARD 1 -i "$WIFI_IF" -o "$ETH_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    # Refuerzo de NAT (aunque NM lo hace, esto asegura que salga por la WiFi correcta)
    iptables -t nat -I POSTROUTING 1 -o "$WIFI_IF" -j MASQUERADE
    
    echo -e "${GREEN}[OK] Reglas aplicadas con éxito.${NC}"
}

# ==============================================================================
# LÓGICA PRINCIPAL
# ==============================================================================

# Capturar señales de salida (Ctrl+C, kill, etc) para ejecutar limpieza
trap "limpieza; exit" INT TERM EXIT

# Banner
echo "======================================================"
echo "   ETH TETHERING (Compartir Internet por Ethernet)    "
echo "=========================================="

detectar_interfaces

# Limpieza preventiva por si hubo un cierre abrupto anterior
echo -e "${BLUE}[INFO] Verificando estados previos...${NC}"
# Desactivamos el trap temporalmente para limpiar sin salir
trap - INT TERM EXIT
limpieza
# Reactivamos el trap
trap "limpieza; exit" INT TERM EXIT

configurar_red
aplicar_reglas_firewall

echo "=========================================="
echo -e "${GREEN} INTERNET COMPARTIDO ACTIVO ${NC}"
echo " Ethernet IP (Gateway): $(ip -4 addr show $ETH_IF | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
echo "=========================================="
echo -e "${YELLOW}Presione la tecla 'q' para detener y salir...${NC}"

# Bucle de espera
while : ; do
    read -n 1 -s key
    if [[ $key = "q" ]] || [[ $key = "Q" ]]; then
        echo ""
        break
    fi
done

# Al salir del bucle, el trap 'EXIT' ejecutará la función limpieza automáticamente