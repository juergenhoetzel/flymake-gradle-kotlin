# flymake-gradle-kotlin

A quick hack to use `gradle compileKotlin` as `flymake` backend.

Add the following to your emacs init file:

```elisp
(require 'flymake-gradle-kotlin)
(add-hook kotlin-mode-hook 'flymake-gradle-kotlin-setup)
```
