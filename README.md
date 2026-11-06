# 🖥️ ResToggle

> Change la résolution de ton écran en un raccourci clavier. Léger, sans installation, sans dépendance.

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell&logoColor=white)

ResToggle tourne en arrière-plan et attend un raccourci clavier global (**Ctrl+Alt+R** par défaut). À chaque appui, il passe d'une résolution à l'autre (par exemple **1920×1080 ⇄ 1280×960**) et garde le taux de rafraîchissement actuel (240 Hz, 144 Hz…).

Pratique pour les joueurs qui jouent en **4:3 étiré** et veulent garder leur bureau en 16:9.

---

## ✨ Fonctionnalités

- ⌨️ **Raccourci global** : marche quelle que soit l'application au premier plan
- 🔁 **Bascule** entre deux résolutions
- ⚡ **Garde le taux de rafraîchissement** (pas de retour forcé à 60 Hz)
- 🪶 **Aucune dépendance** : un seul script PowerShell, il s'appuie directement sur l'API Windows
- 🚀 **Démarrage automatique** avec Windows (en option)
- 🔍 **Liste les résolutions** que ton écran accepte

## 📦 Installation

```bash
git clone https://github.com/mgayvallet/resolution-toggle.git
cd resolution-toggle
```

Rien d'autre à installer : PowerShell est déjà présent sur Windows.

## 🚀 Utilisation

### Lancer en arrière-plan

Double-clique sur **`Lancer.bat`**. Le script démarre caché et le raccourci est actif tout de suite.

### Ligne de commande

| Commande | Effet |
|---|---|
| `powershell -ExecutionPolicy Bypass -File ResToggle.ps1` | Lance l'écoute du raccourci |
| `powershell -ExecutionPolicy Bypass -File ResToggle.ps1 -Once` | Change la résolution une fois puis s'arrête |
| `powershell -ExecutionPolicy Bypass -File ResToggle.ps1 -ListModes` | Liste les résolutions que l'écran accepte |

### Démarrage automatique

1. Appuie sur `Win + R` et tape `shell:startup`.
2. Mets dans ce dossier un raccourci vers `Lancer.bat`.

### Arrêter le script

Dans le Gestionnaire des tâches, termine le processus `powershell.exe` qui fait tourner `ResToggle.ps1`.

## ⚙️ Configuration

Modifie le bloc `CONFIG` en haut de [`ResToggle.ps1`](ResToggle.ps1) :

```powershell
$ResA = @{ W = 1920; H = 1080 }   # résolution normale
$ResB = @{ W = 1280; H = 960 }    # résolution alternative
$Modifiers = 1 + 2                # Alt=1, Ctrl=2, Shift=4, Win=8 (à additionner)
$Key       = 0x52                 # touche 'R'
```

Quelques codes de touches courants :

| Touche | Code |
|---|---|
| `R` | `0x52` |
| `Entrée` | `0x0D` |
| `F9` | `0x78` |
| `F10` | `0x79` |

> 💡 Évite **Alt+Entrée** : beaucoup de jeux et d'applications l'utilisent déjà pour passer en plein écran.

## 🎮 Jeux et anti-cheat

ResToggle **n'interagit avec aucun jeu** : il ne lit pas leur mémoire, n'injecte rien, n'installe aucun driver et n'envoie aucune touche à ta place. Il appelle seulement les fonctions Windows `RegisterHotKey` et `ChangeDisplaySettings`, comme le panneau NVIDIA ou les paramètres d'affichage de Windows.

> ⚠️ Aucun éditeur d'anti-cheat ne publie la liste de ce qu'il détecte. Tu utilises ResToggle sous ta propre responsabilité.

**Conseil :** change la résolution **avant** de lancer un jeu en plein écran exclusif, puis choisis la même résolution dans les options du jeu.

## 🛠️ Fonctionnement

Le script compile à la volée une petite classe C# (`Add-Type`) qui appelle `user32.dll` :

- `RegisterHotKey` et `GetMessage` pour écouter le raccourci global
- `EnumDisplaySettings` pour lire la résolution actuelle et celles que l'écran accepte
- `ChangeDisplaySettings` pour appliquer la nouvelle résolution, avec le même taux de rafraîchissement si possible
