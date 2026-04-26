# Codex Desktop RTL

Codex Desktop RTL מפעיל עותק של Codex Desktop עם תיקון RTL/BiDi לטקסט עברי שמשולב עם אנגלית.

הכלי לא משנה את ההתקנה הרשמית של Codex תחת `C:\Program Files\WindowsApps`.

## מה הכלי עושה

- מוצא את ההתקנה המקומית הרשמית של Codex Desktop.
- מעתיק את תיקיית האפליקציה אל `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected`.
- מזריק תיקון CSS קטן לתוך העותק של `resources\app.asar`.
- מעדכן את מנגנון ה־Electron ASAR integrity בתוך העותק של `Codex.exe`.
- מפעיל את העותק המוזרק.
- יוצר קיצור דרך בשולחן העבודה בשם `Codex Desktop RTL`.
- אם Codex הרשמי מתעדכן, הכלי מזהה את זה ובונה מחדש את העותק המוזרק.
- מפעיל את העותק עם תיקיית user-data נפרדת כדי שיוכל להיפתח ליד Codex הרשמי.

## הרצה

```powershell
.\dist\CodexDesktopRTL.exe
```

הארטיפקט הנוכחי:

```text
dist/CodexDesktopRTL.exe
SHA256: A0877E325CF6F1D663E52B771E71D4C698EFE9F102237502D2B133008ADA7A99
```

ייתכן ש־Windows יציג אזהרת SmartScreen כי הקובץ עדיין לא חתום.

## בנייה

דרישות:

- Windows.
- Codex Desktop מותקן.
- Visual Studio Build Tools 2019 ומעלה עם `ml64.exe`, `link.exe`, ו־Windows SDK `rc.exe`.
- PowerShell 7 מומלץ. Windows PowerShell משמש fallback.

בניית EXE:

```powershell
.\Build-CodexDesktopRTL-All.ps1
```

## איך זה עובד

ה־EXE הוא launcher native קטן שמכיל בתוכו את סקריפטי ה־PowerShell והאייקון. בזמן הרצה הוא מחלץ אותם אל:

```text
%LOCALAPPDATA%\CodexDesktopRTL\Payload
```

אחר כך הוא מריץ את `CodexDesktopRTL-Portable.ps1`, שמאתר את Codex הרשמי, מעתיק אותו ל־`%LOCALAPPDATA%`, מזריק תיקון RTL לתוך ה־ASAR, מעדכן integrity, יוצר shortcut ומפעיל את העותק עם `CODEX_ELECTRON_USER_DATA_PATH` נפרד.

ההתקנה הרשמית של Codex לא משתנה.

## מגבלות כרגע

- Windows בלבד.
- ה־EXE עדיין לא חתום.
- התיקון תלוי במבנה הפנימי הנוכחי של Codex Desktop.
- הכלי לא סוגר את Codex הרשמי בכוונה, כדי לא להרוג את הסשן שממנו העבודה הזאת רצה.
