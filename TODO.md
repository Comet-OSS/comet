# TODO

## Loading method

::: URGENT, do this before any release!

The script should not load automatically when you call the returned loader. You should have to use .Load()

This will prevent the need for a seperate API file to be built.

## API

As part of the above:

Make a API returned by the loadstring so that people can register commands and etc.

## Default commands

We need more default commands. More will be added to the list as it grows

- Fly
- Noclip
- Walkspeed <Speed: number?>
- JumpPower <Speed: number?>

## (?) Argument support

n1 This should be clean and native feeling. It shouldnt just be extra text it should auto append a field when you press enter on a command requiring additional arguments.

---

HOWEVER

im still split on if i want to do commands this way, I never liked this whole idea of arguments in text (yes this is how everyone does it and i dont want to make a seperate UI for it, but i also dont like this. Ill figure it out soon.)

---

Anyways continuing on n1, a good reference is discord slash commands, if they require additional arguments it will show them in a seperate box as well as tell you to the side there are additional *optional arguments (if there is any), this is a good implementation if i decide to use cmd arguments.

## Remote Spy, Instance spy to extend palette instance search, and more

This will eventually need to be added.
