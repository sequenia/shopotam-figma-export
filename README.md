# FigmaExport

<img src="images/logo.png"/><br/>

[![SPM compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/sequenia/figma-export/blob/master/LICENSE)


* getTypography - стили шрифтов
* getSpaceTokens - размерная сетка UI
* getSVGImages - получение SVG
* getColors - получение цветов

## Установка 

Устанавливаем Homebrew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Дальше устанавливаем экспортер
```
brew install sequenia/formulae/figma-export
```

Для обновления запускаем команду 
```
brew upgrade sequenia/formulae/figma-export
```


## Использование Android

В конфигурационный фаил добавляем масив проектов 

```
  projects:
  - name: Deste
      iconURL: URL
      colorURL: URL
      typographyURL: URL
      spaceTokensURL: URL

```

Добавляем пути для сгенерированных файлов. Для `spaceTokens` нужно указать темы скругления 
  - smooth
  - none
  - rounded

  ```
  typography:
    outputFileName: "TypographySystem.kt"
    outputfilePath: "./app/src/main/java/com/shopotam/app/ui/theme"

  colors:
    # Where to place colors relative to `mainRes`?
    outputFileName: "ColorSystem.kt"
    outputfilePath: "./app/src/main/java/com/shopotam/app/ui/theme"

  spaceTokens:
    roundedTheme: "smooth"
    outputFileName: "ColorSystem.kt"
    outputfilePath: "./app/src/main/java/com/shopotam/app/ui/theme"
    ```