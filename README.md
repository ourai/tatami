# Hanger
[![Stories in Ready](https://badge.waffle.io/ourai/hanger.png?label=ready)](https://waffle.io/ourai/hanger)
[![Build Status](https://travis-ci.org/ourai/hanger.png?branch=master)](https://travis-ci.org/ourai/hanger)
[![Built with Grunt](https://cdn.gruntjs.com/builtwith.png)](http://gruntjs.com/)

从项目开发中积累而来，并为新项目的产生而服务！

该框架为项目开发的基础设施，包含了一些项目中常用的功能。

## 构成

- **Core**
  - Sandbox
  - Internationalization
  - Request (AJAX & SJAX)
- **UI**
  - Dialog
  - Tabs
  - Returen to top

## 用法

保证代码运行的核心的三个方法分别为：

1. `prepare()` - 把要在 DOM TREE 构建完成之前执行的一些处理函数加入到内部函数队列中，主要用来进行初始化操作。**该方法可以在任何时候调用。**
2. `ready()` - 把需在 DOM TREE 构建完成之后执行的一些处理函数加入到内部函数队列中。**该方法可以在任何时候调用。**
3. `sandbox()` - 用来启动封闭运行环境，可以将服务端脚本输出的一些系统变量（或常量）作为参数传入到`sandbox()`的内部环境中。**该方法必须在整个页面的最后调用。**

```html
<html lang="zh" dir="ltr">
  <head>
    <meta charset="UTF-8">
    <title>Demo</title>
  </head>
  <body>
    <h1>What is this?</h1>
    <script>
      Hanger.prepare(function() {
        // To do sth. before DOM tree done.
        alert("1");
      });
      
      Hanger.ready(function() {
        // To do sth. after DOM tree done.
        alert("3");   // Will run after 'alert("1")' and 'alert("2")'
      });
      
      Hanger.prepare(function() {
        // To do sth. before DOM tree done.
        alert("2");   // Will run after 'alert("1")';
      });
    </script>
    <p>It is a demo.</p>
    <script>
      // Start the sandbox.
      // Handlers added by 'Hanger.prepare()' and 'Hanger.ready()' will execute.
      Hanger.sandbox({
        platform: "Hanger Project",
        version: "0.0.1"
      });
    </script>
  </body>
</html>
```

其他常用方法：

1. `queue()` - 将一个函数保存到内部，防止造成函数名污染。**建议将全局函数通过这种方式定义。**
2. `run()` - 调用保存到内部的函数。
