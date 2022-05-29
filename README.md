# nimc2
<div>
<img src="https://img.shields.io/github/stars/d4rckh/nimc2"></img>
<a href="https://github.com/d4rckh/nimc2/issues">
  <img src="https://img.shields.io/github/issues/d4rckh/nimc2"></img>
</a>
<a href="https://github.com/d4rckh/nimc2/network">
  <img src="https://img.shields.io/github/forks/d4rckh/nimc2"></img>
</a>
<a href="https://github.com/d4rckh/nimc2/blob/main/LICENSE">
  <img src="https://img.shields.io/github/license/d4rckh/nimc2"></img>
</a>
<img src="https://img.shields.io/github/languages/top/d4rckh/nimc2"></img><br>
</div>

**nimc2** is a very lightweight C2 written **fully in nim** (implant & server). If you want to give it a try check out the [wiki](https://github.com/d4rckh/nimc2/wiki) to learn how to install and use nimc2. It's features include:
- Windows & Linux implant generation
- TCP socket communication (with HTTP communication coming soon)
- Ability to create as many listeners as you want
- A nice task system
- Easy to use CLI
- ...and a lot more features coming soon

![image](https://user-images.githubusercontent.com/35298550/167257694-1cda7f5c-a013-4910-af93-f51ad1d6ca4a.png)

Join the [Discord](https://discord.gg/kCjkfQEB) to discuss about this project.

# Wiki

## Getting started

- [Installation](https://github.com/d4rckh/nimc2/wiki/Installation)
- [Nimc2 crash course](https://github.com/d4rckh/nimc2/wiki/Usage)
- [FAQs](https://github.com/d4rckh/nimc2/wiki/FAQs)

## Guides

- [Managing listeners](https://github.com/d4rckh/nimc2/wiki/Managing-listeners)
- [Creating implants](https://github.com/d4rckh/nimc2/wiki/Creating-implants)
- [Interacting and managing clients](https://github.com/d4rckh/nimc2/wiki/Interacting-and-managing-clients)

## Operating System support

The server is fully supported on Linux but unknown on Windows. The client is fully supported on Windows, with lack of features on Linux.

### Server Support

All server features are available on both Linux and Windows platforms. You might need to install additional dependencies on both platform for cross-platform compilation (check installation wiki page)


### Implant Support

| Feature | Windows Support | Linux Support |
|---|---|---|
| shell command | ✅ | ✅ |
| cmd command | ✅ | ❌ `(cmd.exe not present on linux)` |
| info command | ✅ | ⚠️ |
| msgbox command | ✅ | ❌ |
| processes command | ✅ | ❌ |
| tokeninfo command | ✅ | ❌ |
| download command | ✅ | ✅ |
| upload command | ✅ | ✅ |

✅ - yes, complete
⚠️ - yes, but partially
❌ - no, does not work at all

# Support Me

You can support me by becoming a patreon at **[https://www.patreon.com/d4rckh](https://www.patreon.com/d4rckh)** (You also get some exclusive things)