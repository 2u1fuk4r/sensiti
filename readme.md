```{=html}
<p align="center">
```
███████╗███████╗███╗ ██╗███████╗██╗████████╗██╗ ██╔════╝██╔════╝████╗
██║██╔════╝██║╚══██╔══╝██║ ███████╗█████╗ ██╔██╗ ██║███████╗██║ ██║ ██║
╚════██║██╔══╝ ██║╚██╗██║╚════██║██║ ██║ ██║ ███████║███████╗██║
╚████║███████║██║ ██║ ██║ ╚══════╝╚══════╝╚═╝ ╚═══╝╚══════╝╚═╝ ╚═╝ ╚═╝

🔍 Sensitive Data & Secret Discovery Engine\
🚀 sensiti.sh

Advanced Sensitive Data & Secret Exposure Detection Tool\
Built for bug bounty hunters, red teamers, and recon automation.

```{=html}
</p>
```

------------------------------------------------------------------------

## 🎯 What It Does

`sensiti.sh` scans URL datasets to detect:

🔐 Secrets • 🗂 Sensitive files • ☁ Cloud credentials\
🗄 Database strings • 🛠 DevOps tokens\
🔄 Open redirects • 🧪 Debug endpoints • 🧾 JWT tokens

High-signal. Low-noise.

------------------------------------------------------------------------

## ⚡ Usage

``` bash
bash sensiti.sh -f urls.txt
```

Specific module:

``` bash
bash sensiti.sh -f urls.txt -c cloud
```

Silent mode:

``` bash
bash sensiti.sh -f urls.txt -s
```

------------------------------------------------------------------------

## 📁 Output

    sensitive_YYYYMMDD/
    ├── all_hits.txt
    └── SUMMARY.txt

------------------------------------------------------------------------

```{=html}
<p align="center">
```
![Bash](https://img.shields.io/badge/Bash-Script-black?style=flat-square&logo=gnu-bash)
![Status](https://img.shields.io/badge/Status-Stable-success?style=flat-square)
![Purpose](https://img.shields.io/badge/Purpose-Offensive%20Security-red?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

```{=html}
</p>
```
