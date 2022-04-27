# nimc2

t obe used only for educational purposes

## usage

1. start a tcp listener: `startlistener TCP 127.0.0.1 1234`
    - then you can view your listeners using `listeners`
2. run the client, change the ip address and port if necessary 
3. verify that it connected using `clients` and `clientlisteners`
4. switch to the client using `interact 0` (aka. interact with it)
5. run commands
    - `info`
    - `shell whoami`
    - `cmd dir`

## todo's
- [X] handle clients
- [ ] a protocol with which clients connect with the server
- [X] basic commands
    - [X] `clients` - list clients
    - [X] `switch [client id]` - switch to a client
    - [X] `info` - show information about a client
    - [X] `shell` - run commands 
- [ ] more advanced commands
    - [ ] screenshot
    - [ ] file upload and download
    - [ ] get current running desktop apps
    - [ ] getsystem
    - [ ] dumpsam
    - [ ] key logging
    - [ ] webcam shot
    - [ ] msg boxes
- [ ] get more info about clients (e.g. are we running as admin?)
- [ ] persistence methods
- [ ] http communication
- [ ] dns communication
- [ ] GUI (desktop app / web app)
- [ ] implant generation
- [X] implement a way to add multiple listeners
- [ ] find fancy names for clients, listeners, etc
- please suggest cool stuff in issues or make a PR editing this list

## screenshot

![no](https://media.discordapp.net/attachments/934769201707622400/968461979427688478/unknown.png)

### discuss 

[Discord](https://discord.gg/kCjkfQEB)
