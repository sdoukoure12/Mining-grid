# Mining Grid – Setup and Usage Instructions

This guide provides step-by-step instructions for setting up and using a mining grid—a collection of interconnected mining rigs working together to maximize hashing power and efficiency. Whether you are building a small home grid or scaling up a larger operation, these instructions cover hardware assembly, software installation, configuration, monitoring, and best practices.

---

## 1. Introduction

A mining grid consists of multiple mining rigs (each with GPUs or ASICs) connected via a network and managed collectively. Benefits include:

- Increased total hash rate
- Redundancy and load balancing
- Centralized monitoring and control
- Easier scaling

This guide assumes you have basic knowledge of computer hardware, networking, and cryptocurrency mining.

---

## 2. Hardware Requirements

### 2.1. Mining Rigs

- GPUs (for algorithms like Ethash, KawPow, etc.) or ASICs (for SHA-256, Scrypt, etc.)
- Motherboard with enough PCIe slots
- CPU (low-end is sufficient)
- RAM (minimum 4GB per rig)
- Storage (SSD recommended, 120GB+)
- Power Supply Unit(s) with sufficient wattage and connectors
- Risers (for GPUs) or appropriate cables
- Cooling fans and ventilation

### 2.2. Network Infrastructure

- Gigabit switch (connect all rigs and a management computer)
- Ethernet cables
- Router with stable internet connection
- Optional: dedicated management server or Raspberry Pi for monitoring

### 2.3. Electrical Considerations

- Dedicated circuits with adequate amperage
- PDU (Power Distribution Unit) for organized power
- Surge protectors and UPS for critical components

### 2.4. Environment

- Well-ventilated area or mining shed
- Temperature and humidity monitoring
- Fire safety equipment

---

## 3. Software Setup

### 3.1. Operating System

Choose an OS that supports your mining software. Popular options:

- **Windows 10/11** – Easy for beginners, good driver support.
- **Linux (Ubuntu, HiveOS, etc.)** – More stable, lower overhead, remote management.

For a grid, consider a specialized mining OS like HiveOS, SimpleMining, or RaveOS, which offer web-based dashboards and fleet management.

### 3.2. Mining Software

Select software compatible with your hardware and the coin you mine:

- For GPUs: TeamRedMiner (AMD), NBMiner, lolMiner, T-Rex (NVIDIA), PhoenixMiner.
- For ASICs: Firmware like Braiins OS, Vnish, or stock firmware.

### 3.3. Drivers

- **NVIDIA:** Install latest Game Ready or Studio drivers.
- **AMD:** Install Radeon Software Adrenalin or Pro drivers.
- **ASICs:** Firmware updates via manufacturer.

### 3.4. Network Configuration

- Assign static IPs to each rig via DHCP reservation or manual configuration.
- Ensure all rigs are on the same subnet for easy management.

---

## 4. Configuration

### 4.1. Basic Rig Setup

1. Assemble each rig: install CPU, RAM, SSD, connect PSU, mount GPUs with risers.
2. Connect to network and power on.
3. Install OS and drivers.
4. Test each GPU/ASIC individually using mining software to ensure stability.

### 4.2. Mining Pool Selection

Choose a mining pool that supports your chosen coin. Common pools: Ethermine, F2Pool, Poolin, etc. Create an account and get the pool URL and port.

### 4.3. Mining Software Configuration

Create a batch file (Windows) or script (Linux) with your wallet address, pool URL, and any additional parameters.

Example for T-Rex (NVIDIA) on Windows:

```batch
t-rex.exe -a ethash -o stratum+tcp://us1.ethermine.org:4444 -u YOUR_WALLET_ADDRESS.WORKER_NAME -p x
```

Save as `start_mining.bat` and run.

### 4.4. Grid Management Software

To manage multiple rigs, use a centralized platform:

- **HiveOS:** Install HiveOS image on each rig, register them in your HiveOS account, and configure from the web dashboard.
- **Awesome Miner:** Install on a management PC, add rigs via IP, and monitor/control.
- **Custom solution:** Use SSH for Linux rigs or Remote Desktop for Windows.

### 4.5. Overclocking / Underclocking

Optimize performance/power ratio:

- Use MSI Afterburner (Windows) or command-line tools (Linux) to set core clock, memory clock, power limit, and fan speed.
- In HiveOS, you can apply overclocking profiles per rig.

> ⚠️ **Warning:** Improper overclocking can cause instability or hardware damage. Start conservatively and stress-test.

---

## 5. Monitoring and Management

### 5.1. Real-Time Monitoring

- Use mining pool dashboards to view hash rate and earnings.
- Use management software (HiveOS, Awesome Miner) to see individual rig status, temperatures, fan speeds, and errors.
- Set up alerts for high temps, low hash rate, or offline rigs.

### 5.2. Remote Access

- Enable SSH (Linux) or RDP (Windows) for remote troubleshooting.
- Use VPN for secure access from outside your local network.

### 5.3. Maintenance

- Regularly clean dust from components.
- Check connections and cables.
- Update software and drivers when beneficial.
- Monitor electricity usage and costs.

### 5.4. Scaling

- When adding new rigs, repeat the setup process and add them to your management system.
- Ensure your electrical and network infrastructure can handle the additional load.

---

## 6. Troubleshooting Common Issues

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| Rig not hashing | Software not running, driver issue, pool unreachable | Restart miner, check logs, update drivers, verify pool URL |
| Low hash rate | Thermal throttling, incorrect overclock, malware | Check temps, reduce OC, scan for malware, ensure correct algorithm |
| Crashes/reboots | Power supply insufficient, unstable OC, overheating | Check PSU capacity, lower OC, improve cooling |
| GPU not detected | Loose riser, driver issue, BIOS settings | Reseat GPU/riser, reinstall drivers, enable 4G decoding in BIOS |
| Network disconnects | Faulty cable, switch port, IP conflict | Replace cable, try different port, renew IP lease |

---

## 7. Conclusion

Setting up a mining grid requires careful planning, but the rewards can be significant when done correctly. Start small, test each component, and gradually scale up. Use management tools to simplify monitoring and maintenance. Always prioritize safety—electrical, fire, and ventilation—and stay informed about cryptocurrency trends and algorithm changes.

For further assistance, consult community forums (BitcoinTalk, Reddit r/gpumining) and official documentation of your chosen software.

---

> **Disclaimer:** Mining involves financial risk due to volatile cryptocurrency prices and hardware costs. Ensure compliance with local regulations and electricity costs. 