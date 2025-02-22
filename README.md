![ASSEMBLY](https://img.shields.io/badge/_-ASM-6E4C13.svg?style=for-the-badge)

# General information

This repository contains assembler projects in DOSBox.

## 01Hello

The first program is "**Hello, world!**", but a little differently...

## 02Boxes

The program draws a frame and text in it in video memory.
The command line takes **5 arguments:** 
1. frame size in X coordinate
2. frame size in Y coordinate
3. color
4. style number*
5. line that should be in the frame

   
Program call example:
```
~>02Boxes.com 50 10 95 2 ""be brave#"
```

Result:
![result of 1-st example](/images/example-1.png "be brave, brother")

**\* means a peculiarity:** if you select the style numbered "0", you can set your own frame style of 9 characters. There is an example of such a program call:
```
~>02Boxes.com 60 13 97 0 "(-)( )(-)" "stay hard#"
```

Result
![result of 1-st example](/images/example-2.png "stay hard, my man")

## 03Interrupts

In this program I intercept DOS hardware interrupt 09h and set my own handler interrupt.
