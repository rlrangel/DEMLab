[release_image]:       https://img.shields.io/badge/release-1.0-green.svg?style=flat
[releases_link]:       https://gitlab.com/rafaelrangel/demlab/-/releases
[license_image]:       https://img.shields.io/badge/license-MIT-green.svg?style=flat
[license_link]:        https://gitlab.com/rafaelrangel/demlab/-/blob/master/LICENSE
[file_exchange_image]: https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg
[file_exchange_link]:  https://www.mathworks.com/matlabcentral/fileexchange/69801-lesm-linear-elements-structure-model
[zenodo_image]:        https://zenodo.org/badge/DOI/10.5281/zenodo.3234644.svg
[zenodo_link]:         https://doi.org/10.5281/zenodo.3234644
[matlab_website]:      https://www.mathworks.com/
[cimne_website]:       https://www.cimne.com/
[upc_website]:         https://camins.upc.edu/
[mathegram_website]:   https://www.surrey.ac.uk/mathegram
[mit_license_link]:    https://choosealicense.com/licenses/mit/

# DEMLab - Discrete Element Method Laboratory

<p align=center><img height="100.0%" width="100.0%" src="https://gitlab.com/rafaelrangel/demlab/-/raw/master/docs/images/logos/logo_demlab.png"></p>

[![Release][release_image]][releases_link] [![License][license_image]][license_link] [![FileExchange][file_exchange_image]][file_exchange_link] [![DOI][zenodo_image]][zenodo_link]

DEMLab is a program for performing numerical simulations of particle systems using the Discrete Element Method (DEM).
This program uses the Discrete Element Method (DEM) to simulate particulate systems.

Its purpose is to offer a modular environment for readily implementing and testing DEM models in small to medium-scale problems.
The program is designed to be a modular and extensible tool to allow testing of different models and formulations.

## Table of Contents
- [Main Features](#main-features)
- [Implementation Aspects](#implementation-aspects)
- [Instructions](#instructions)
    - [Input Files](#input-files)
	- [Running Simulations](#running-simulations)
	- [Loading Results](#loading-results)
	- [Testing](#testing)
- [Examples](#examples)
- [Documentation](#documentation)
- [How to Contribute](#how-to-contribute)
- [How to Cite](#how-to-cite)
- [Authorship](#authorship)
- [Acknowledgement](#acknowledgement)
- [License](#license)

## Main Features

The DEM is a numerical method...
soft-sphere approach
particles keep their shape
interaction models
a particles method for modeling the bulk behavior of granular materials and many geomaterials such as coal, ores, soil, rocks, aggregates, pellets, tablets and powders.
The DEM is a numerical method that has been applied to simulate and analyze flow behavior in a wide range of disciplines including mechanical and process engineering, pharmaceutical, materials science, agricultural engineering and more. 

Mechanical, thermal and themomechanical simulations can be performed.

Only two-dimensional (2D) models are handled.

**Analysis Types**

- Mechanical (motion of particles)
- Thermal (temperature of particles)
- Thermo-mechanical (motion and temperature of particles)

**Problem Types**

Two-dimensional (2D) problems.

**Element Types**

- Spherical particle
- Cylindrical particle

**Outputs**

- Graphs
- Animations

## Implementation Aspects

Written in the [MATLAB][matlab_website] programming language.
OOP.
Code efficiency is not a priority and, therefore, only small-scale problems should be simulated.
Kratos applications.

## Instructions

Lorem ipsum dolor sit amet. Ad totam nihil in officia mollitia a quibusdam rerum qui error consequatur. Cum sint quaerat ut voluptatum libero sit fugiat distinctio ea dolor facilis ea aliquid velit At velit dolore? Vel sunt dolorem non ipsum amet in eaque accusamus ut aliquam odit ut tempore reiciendis est recusandae aliquam..

### Input Files

Lorem ipsum dolor sit amet. Ad totam nihil in officia mollitia a quibusdam rerum qui error consequatur. Cum sint quaerat ut voluptatum libero sit fugiat distinctio ea dolor facilis ea aliquid velit At velit dolore? Vel sunt dolorem non ipsum amet in eaque accusamus ut aliquam odit ut tempore reiciendis est recusandae aliquam..

### Running Simulations

To run a simulation, execute this script and select an appropriate parameters file with the _.json_ extension.
Multiple parameter files can be selected to run simulations sequentially, as long as they are located in the same folder.
Sub-folders with the simulation name plus the suffix "_out" are created to receive the output files with the results of each simulation.

### Loading Results

To load and show results from a previously run simulation, execute this script and select an appropriate storage file with the _.mat_ extension.
Multiple storage files can be selected to load and show results sequentially, as long as they are located in the same folder.
Furthermore, if a storage file named after the simulation name is located in the same folder of the parameters file, the simulation is restarted from the stored results.

### Testing

This script file runs the selected test models and checks if the obtained results agree with the reference results.

This script file generates / updates the reference result files of the selected test models.
ATTENTION: This action will overwrite existing reference results.

## Examples

Lorem ipsum dolor sit amet. Ad totam nihil in officia mollitia a quibusdam rerum qui error consequatur. Cum sint quaerat ut voluptatum libero sit fugiat distinctio ea dolor facilis ea aliquid velit At velit dolore? Vel sunt dolorem non ipsum amet in eaque accusamus ut aliquam odit ut tempore reiciendis est recusandae aliquam..

## Documentation

This program adopts an Object Oriented Programming (OOP) paradigm.
The following OOP super-classes are implemented:

## How to Contribute

New implementations can be made by anyone in separate branches.

The merge of new developments into the master branch is subjected to the author's approval upon a **merge request**.

## How to Cite

Lorem ipsum dolor sit amet. Ad totam nihil in officia mollitia a quibusdam rerum qui error consequatur. Cum sint quaerat ut voluptatum libero sit fugiat distinctio ea dolor facilis ea aliquid velit At velit dolore? Vel sunt dolorem non ipsum amet in eaque accusamus ut aliquam odit ut tempore reiciendis est recusandae aliquam.

## Authorship

- **Rafael Rangel** (<rrangel@cimne.upc.edu>)

International Center for Numerical Methods in Engineering ([CIMNE][cimne_website]) 
and
Polytechnic University of Catalonia ([UPC BarcelonaTech][upc_website])

<p float="left">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://gitlab.com/rafaelrangel/demlab/-/raw/master/docs/images/logos/logo_cimne.png" width="350"/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://gitlab.com/rafaelrangel/demlab/-/raw/master/docs/images/logos/logo_upc.png" width="350"/> 
</p>

## Acknowledgement

The program was initially developed under the context of the [MATHEGRAM project][mathegram_website],
a Marie Sklodowska-Curie Innovative Training Network of the European Union’s Horizon 2020 Programme H2020 under REA grant agreement No. 813202.

<p float="left">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://gitlab.com/rafaelrangel/demlab/-/raw/master/docs/images/logos/logo_mathegram.png" width="600"/>
</p>

## License

DEMLab is licensed under the [MIT license][mit_license_link],
which allows the program to be freely used by anyone for modification, private use, commercial use, and distribution, only requiring preservation of copyright and license notices.
No liability and warranty are provided.
