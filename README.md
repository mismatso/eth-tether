# eth-tether

![Diagrama de red que muestra la configuración de eth-tether para compartir internet por WiFi a Ethernet. El diagrama muestra un host Linux con Debian o Ubuntu y conexión WiFi a un router/ISP. El host ejecuta NetworkManager con método IPv4 compartido, reglas de iptables para reenvío de alta prioridad y NAT/Masquerade, y un servidor DHCP/DNS para la configuración automática del cliente. Tres dispositivos cliente están conectados mediante un switch Ethernet: PC, portátil y tableta cliente. El diagrama muestra la omisión de iptables y NetworkManager con configuración efímera. El contenedor Docker se muestra como omitido. Todos los componentes están conectados mediante líneas de red que indican el flujo de datos en un estilo de ilustración técnica claro.](/images/eth-tether-banner.png)

**eth-tether** es una utilidad de CLI ligera para Linux (Debian/Ubuntu) que comparte la conexión de Internet WiFi a través de un puerto Ethernet de manera efímera.

Diseñado específicamente para resolver conflictos de enrutamiento en entornos de desarrollo que utilizan **Docker**, donde las reglas de firewall predeterminadas suelen bloquear el tráfico compartido.

## 🚀 Características

* **Autodetección:** Identifica automáticamente las interfaces WiFi (WAN) y Ethernet (LAN).
* **Bypass de Docker:** Inyecta reglas de `iptables` con alta prioridad para permitir el tráfico `FORWARD` sin desactivar Docker.
* **Efímero:** Limpieza automática (Garbage Collection) al salir. No deja residuos de configuración en el sistema.
* **Plug & Play:** Levanta un servidor DHCP y DNS automáticamente para los clientes conectados.

## 📋 Requisitos

* OS: Debian 12+, Ubuntu 22.04+ o derivados.
* Dependencias: `network-manager`, `iptables`.
* Privilegios: `root` (sudo).

## 🛠️ Instalación y Uso

**eth-tether** es parte de la suite de herramientas [scriptorium](https://github.com/mismatso/scriptorium). Para instalar y usar **eth-tether**, sigue estos pasos:

1. Descarga el script `eth-tether.sh`:

    Si tiene `curl` instalado:
    ```bash
    curl -o eth-tether.sh -L https://raw.githubusercontent.com/mismatso/eth-tether/main/scripts/eth-tether.sh
    ```
    Si prefiere usar el clásico `wget`:
    ```bash
    wget -O eth-tether.sh https://raw.githubusercontent.com/mismatso/eth-tether/main/scripts/eth-tether.sh
    ```

2. Crea un directorio para alojar los scripts:
   ```bash
   sudo mkdir -p /opt/librecia/scriptorium
   ```

3. Mueve el script `eth-tether` a este directorio:
   ```bash
   sudo mv eth-tether.sh /opt/librecia/scriptorium
   ```

4. Otorga permisos de ejecución al script `eth-tether.sh`:
   ```bash
   sudo chmod o+x /opt/librecia/scriptorium/eth-tether.sh
   ```

5. Crea un enlace simbólico para ejecutarlo desde cualquier ubicación:
   ```bash
   sudo ln -s /opt/librecia/scriptorium/eth-tether.sh /usr/local/bin/eth-tether
   ```

6. ¡Listo! Ahora puedes ejecutar `eth-tether` desde cualquier ubicación en tu sistema.

    ```bash
    sudo eth-tether
    ```

4.  **Detener:** Presione `q` o `Ctrl+C` para detener la compartición y restaurar las reglas de firewall originales.

## 📄 Licencia

[eth-tether](https://github.com/mismatso/eth-tether) © 2025 by [Misael Matamoros](https://t.me/mismatso) está licenciado bajo la **GNU General Public License, version 3 (GPLv3)**. Para más detalles, consulta el archivo [LICENSE](/LICENSE).

!["GPLv3"](https://www.gnu.org/graphics/gplv3-with-text-136x68.png)