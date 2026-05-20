# Codex Desktop RTL

Codex Desktop RTL הוא launcher ל־Windows שיוצר עותק מקומי של Codex Desktop עם תיקון RTL/BiDi לעברית שמשולבת עם אנגלית.

זה פרויקט עצמאי. זה לא מוצר של OpenAI, לא כולל את Codex Desktop, ולא משנה את ההתקנה הרשמית תחת `C:\Program Files\WindowsApps`.

## הורדה

למשתמש רגיל, מורידים ZIP ומריצים את ה־EXE שבתוכו:

- [CodexDesktopRTL-v0.1.0-Windows.zip](dist/CodexDesktopRTL-v0.1.0-Windows.zip)

ארטיפקטים נוספים:

- [CodexDesktopRTL.exe](dist/CodexDesktopRTL.exe)
- [CHECKSUMS.txt](dist/CHECKSUMS.txt)

## התקנה

1. מתקינים קודם את Codex Desktop הרשמי.
2. מורידים את `CodexDesktopRTL-v0.1.0-Windows.zip`.
3. מחלצים את ה־ZIP.
4. לוחצים פעמיים על `CodexDesktopRTL.exe`.
5. אם Windows SmartScreen מזהיר, בוחרים `More info` ואז `Run anyway` רק אם סומכים על המקור.

אחרי ההרצה הראשונה נוצר קיצור דרך בשולחן העבודה בשם `Codex Desktop RTL`.

## מה הכלי עושה

- מאתר את Codex Desktop הרשמי שמותקן במחשב.
- מעתיק את תיקיית האפליקציה הרשמית אל `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected`.
- מזריק תיקון RTL/BiDi לתוך העותק של `resources\app.asar`.
- מעדכן Electron ASAR integrity בתוך העותק של `Codex.exe`.
- מפעיל את העותק עם תיקיית user-data מבודדת.
- יוצר או מעדכן shortcut.
- בונה מחדש את העותק המקומי כש־Codex הרשמי מתעדכן.

## מה הכלי לא עושה

- לא משנה את `C:\Program Files\WindowsApps`.
- לא משנה את ההתקנה הרשמית של Codex.
- לא כולל קבצי Codex.
- לא מתקין service.
- לא מוסיף startup.
- לא אוסף tokens, cookies, סיסמאות או תוכן שיחות.
- לא פותח פורטים נכנסים.

## הבדל חשוב מול Claude Desktop RTL

Claude Desktop RTL מריץ את Claude הרשמי החתום ומזריק RTL בזמן ריצה.

Codex Desktop RTL כרגע עובד אחרת: הוא יוצר עותק מקומי ומבצע patch לעותק. זו הייתה הדרך האמינה עבור Codex Desktop. זה שקוף ומכוון, אבל סביר יותר לקבל אזהרות SmartScreen/EDR לעומת Claude. להפצה בארגון צריך חתימת קוד ובדיקת endpoint security.

## איך זה עובד

`CodexDesktopRTL.exe` הוא launcher native קטן. בזמן הרצה הוא מחלץ את ה־PowerShell runner, סקריפטי patch והאייקון אל:

```text
%LOCALAPPDATA%\CodexDesktopRTL\Payload
```

ה־PowerShell runner:

1. מאתר את Codex Desktop הרשמי.
2. מעתיק אותו אל `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected`.
3. מזריק תיקון ל־`resources\app.asar`.
4. מעדכן Electron ASAR integrity בעותק של `Codex.exe`.
5. יוצר `%LOCALAPPDATA%\CodexDesktopRTL\UserData`.
6. מפעיל את העותק עם `CODEX_ELECTRON_USER_DATA_PATH` שמצביע לתיקייה המבודדת.

ההתקנה הרשמית של Codex לא משתנה.

## קבצים שנכתבים

```text
%LOCALAPPDATA%\CodexDesktopRTL\
  Payload\
  Codex-Injected\
  UserData\
  CodexDesktopRTL-Portable.ps1
  CodexDesktopRTL.cmd
  CodexDesktopRTL-Launch.cmd
  CodexDesktopRTL.ico
  CodexDesktopRTL.log
  source.marker
```

## הסרה / איפוס

סוגרים את Codex Desktop RTL ואז מריצים:

```powershell
%LOCALAPPDATA%\CodexDesktopRTL\CodexDesktopRTL-Portable.ps1 -Mode reset
```

או מוחקים ידנית:

```text
%LOCALAPPDATA%\CodexDesktopRTL
Desktop\Codex Desktop RTL.lnk
```

ההתקנה הרשמית של Codex לא נפגעת.

## ניהול גרסאות

הפרויקט משתמש ב־Semantic Versioning:

- Patch: תיקונים לאותו ASAR layout, docs, packaging.
- Minor: נתיבי הפצה חדשים או שינויי runtime גדולים יותר.
- Major: שינוי במבנה התקנה או במודל אבטחה.

גרסת Windows נוכחית: `0.1.0`.

## בעיות נפוצות

### Windows SmartScreen מזהיר

ה־EXE עדיין לא חתום. זה צפוי ב־MVP הנוכחי. להפצה בארגון צריך build חתום ב־Authenticode.

### Codex נפתח כסשן נפרד

זה צפוי. העותק משתמש ב־`%LOCALAPPDATA%\CodexDesktopRTL\UserData` כדי לא להתנגש עם הסשן הרשמי של Codex.

### Codex לא נמצא

להתקין קודם את Codex Desktop הרשמי ואז להריץ שוב את `CodexDesktopRTL.exe`.

### RTL הפסיק לעבוד אחרי עדכון Codex

להריץ reset ואז להריץ שוב:

```powershell
%LOCALAPPDATA%\CodexDesktopRTL\CodexDesktopRTL-Portable.ps1 -Mode reset
```

אם זה עדיין נכשל, כנראה Codex שינה את מבנה ה־ASAR וצריך לעדכן את ה־patcher.

### אנטי־וירוס או EDR מזהיר

ה־build מחלץ PowerShell scripts ומבצע patch לעותק מקומי של Electron app. זה שקוף ומכוון, אבל build לא חתום עדיין עלול להיות מסומן. להפצה בארגון צריך חתימת קוד.

## אבטחה ושקיפות

הכלי מבצע patch רק לעותק תחת `%LOCALAPPDATA%`. הוא לא משנה את החבילה הרשמית של Codex. ה־tradeoff הוא שהעותק המקומי משתנה, ולכן זה פחות מתאים לארגונים עד שיש חתימה ובדיקות endpoint security.

מסמכים נוספים:

- [Security](docs/SECURITY.md)
- [Threat model](docs/THREAT_MODEL.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Release process](docs/RELEASE.md)
