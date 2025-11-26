# Novoboard

Novoboard ist ein webbasiertes On- und Offboarding-Management-System für Unternehmen, Kliniken und Organisationen.  
Es bietet eine moderne, mandantenfähige Verwaltung von Prozessen, Dokumenten und Benutzerzugängen – vollständig in PHP entwickelt und vollständig Docker-fähig.

---

## 🚀 Features

### **Benutzer & Rollen**
- Multi-Tenant-Architektur
- Superadmin, Admin und normale Benutzer
- Passwort-Richtlinien pro Rolle
- Lokale und LDAP-Authentifizierung
- Temporäre Account-Sperre nach X Fehlern

### **Onboarding**
- Erstellung von Prozessen für neue Mitarbeitende
- Dokument-Generierung als PDF
- Automatische Ablage von Dateien
- Workflow-Status sichtbar für Admins

### **Offboarding**
- Automatische Erkennung ablaufender AD-Accounts
- Generierung von Offboarding-Checklisten
- Dokumente und Unterschriftsseiten als PDF

### **Administration**
- Mandantenverwaltung
- Benutzerverwaltung
- LDAP-Konfiguration pro Tenant
- Prozesseditor
- Logging & Protokolle

### **Technik**
- PHP 8
- MariaDB
- Nginx
- Composer
- Docker & Docker Compose
- Zero-Config Start innerhalb von 1 Minute

---

**📦 Installation mit Docker**
------------------------------

### **Voraussetzungen**

*   Docker
    
*   Docker Compose (oder “docker compose”)
    

### **Schritt 1: Repository klonen**

git clone https://github.com/Dirk23/Novoboard.git

cd Novoboard

### **Schritt 2: .env erstellen**

cp .env.example .env

Dann folgende Werte in .env anpassen:

*   DB\_USER
    
*   DB\_PASS
    
*   DB\_ROOT\_PASS
    

### **Schritt 3: Container starten**

docker compose up -d

**🌐 Anwendung öffnen**
-----------------------

Standardmäßig erreichbar unter:

http://localhost:8091

**🔧 Update-Prozess**
---------------------

### **Images von Docker Hub ziehen**

docker compose pull

docker compose up -d

### **Eigene Images bauen (wenn du Änderungen gemacht hast)**

docker compose build

docker compose up -d

Die Datenbank bleibt erhalten, da docker/db/data ein persistentes Volume ist.

**🏗 Projektstruktur**
----------------------

Novoboard/

├── docker/                 (Dockerfiles: php, nginx, cron, db)

├── projekt/                (PHP-Projekt: src, public, config, lib)

│   ├── public/             (Webroot: index.php, assets, admin UI)

│   ├── src/                (PHP-Klassen: Auth, HildebrandIT, Util)

│   ├── bin/                (Cron-Skripte, Worker, Maintenance)

│   ├── config/             (SQL-Schemata und Initialdaten)

│   └── storage/            (Cache, temp, Dateien)

├── docker-compose.yml      (Compose für App + DB + Cron + Nginx)

├── .env.example            (Beispiel-Konfiguration)

├── LICENSE                 (MIT License)

├── README.md               (Dieses Dokument)

└── .gitignore

**🧪 Entwicklung ohne Docker (optional)**
-----------------------------------------

cd projekt

composer install

php -S localhost:8080 -t public

Nur sinnvoll, wenn PHP 8 + MariaDB lokal installiert sind.

**🆘 Fehler melden**
--------------------

Bitte nutze die vorgefertigten Issue Templates:

*   Bug Report
    
*   Feature Request
    

Zu finden unter: .github/ISSUE\_TEMPLATE/

**🤝 Beiträge & Pull Requests**
-------------------------------

*   PR-Template verwenden (.github/PULL\_REQUEST\_TEMPLATE.md)
    
*   Keine sensiblen Daten committen
    
*   Tests/Build durchführen (falls vorhanden)
    

Pull Requests sind willkommen!

**📜 Lizenz**
-------------

Dieses Projekt steht unter der MIT-Lizenz.

Siehe LICENSE.

Danke fürs Nutzen von Novoboard!

Für Fragen, Probleme oder Ideen: bitte ein Issue erstellen. 😊
