
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]



<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/ODEX-TOS/system-updater">
    <img src="https://tos.odex.be/images/logo.svg" alt="Logo" width="150" height="200">
  </a>

  <h3 align="center">system updater</h3>

  <p align="center">
    Automatically update your tos environment when a new system is available
    <br />
    <a href="https://github.com/ODEX-TOS/system-updater"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/ODEX-TOS/system-updater">View Demo</a>
    ·
    <a href="https://github.com/ODEX-TOS/system-updater/issues">Report Bug</a>
    ·
    <a href="https://github.com/ODEX-TOS/system-updater/issues">Request Feature</a>
  </p>
</p>



<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Usage](#usage)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)
* [Acknowledgements](#acknowledgements)



<!-- ABOUT THE PROJECT -->
## About The Project


<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

Installing is as easy as the following (make sure the tos repo is in your pacman.conf file)
```sh
pacman -Syu system-updater
```

### Installation
 
1. Clone the system-updater
```sh
git clone https://github.com/ODEX-TOS/system-updater.git
```
2. Run the updater
```sh
system-update # this will scan your system and perform a full upgrade to the latest tos version
```

> Make sure you have a backup of your files incase they are lost. This updater will change your system



<!-- USAGE EXAMPLES -->
## Usage

You can do more than just update your system. For example you can modify the `/etc/system-updater.conf` to match your system

Here is a short list of options you can perform

```sh
system-updater -i # Show your current tos version (--info)
```

```sh
system-updater -d # print what is new in the latest tos version (--difference)
```

```sh
system-updater -v # print the version of the tool (--version)
```

_For more examples, please refer to the [Documentation](https://tos.odex.be/blog)_



<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/ODEX-TOS/system-updater/issues) for a list of proposed features (and known issues).



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

F0xedb - tom@odex.be

Project Link: [https://github.com/ODEX-TOS/system-updater](https://github.com/ODEX-TOS/system-updater)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

* [ODEX-TOS](https://github.com/ODEX-TOS/system-updater)





<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/ODEX-TOS/system-updater.svg?style=flat-square
[contributors-url]: https://github.com/ODEX-TOS/system-updater/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/ODEX-TOS/system-updater.svg?style=flat-square
[forks-url]: https://github.com/ODEX-TOS/system-updater/network/members
[stars-shield]: https://img.shields.io/github/stars/ODEX-TOS/system-updater.svg?style=flat-square
[stars-url]: https://github.com/ODEX-TOS/system-updater/stargazers
[issues-shield]: https://img.shields.io/github/issues/ODEX-TOS/system-updater.svg?style=flat-square
[issues-url]: https://github.com/ODEX-TOS/system-updater/issues
[license-shield]: https://img.shields.io/github/license/ODEX-TOS/system-updater.svg?style=flat-square
[license-url]: https://github.com/ODEX-TOS/system-updater/blob/master/LICENSE.txt
[product-screenshot]: https://tos.odex.be/images/logo.svg
