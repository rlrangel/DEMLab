# DEMLab - Discrete Element Method Laboratory

<p align=center><img height="75.0%" width="75.0%" src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/logos/logo_demlab.png"></p>

[![Release][release-image]][release] [![License][license-image]][license] [![Contributing][contributing-image]][contributing] [![Zenodo][zenodo-image]][zenodo] [![FileExchange][fileexchange-image]][fileexchange]

[release-image]: https://img.shields.io/badge/release-1.0.0-green.svg?style=flat
[release]: https://github.com/rlrangel/DEMLab/releases

[license-image]: https://img.shields.io/badge/license-MIT-green.svg?style=flat
[license]: https://github.com/rlrangel/DEMLab/blob/master/LICENSE

[contributing-image]: https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg
[contributing]: https://github.com/rlrangel/DEMLab/blob/master/CONTRIBUTING.md

[zenodo-image]: https://zenodo.org/badge/DOI/10.5281/zenodo.6509866.svg
[zenodo]: https://doi.org/10.5281/zenodo.6509866

[fileexchange-image]: https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg
[fileexchange]: https://www.mathworks.com/matlabcentral/fileexchange/110965-demlab

DEMLab is a MATLAB program for performing numerical simulations of particle systems using the Discrete Element Method (DEM).

Its purpose is to offer a modular and extensible environment that allows immediate implementation and testing of several DEM models and formulations
in small to medium-scale problems.
It targets researchers, who can use it as a numerical laboratory, and students who want to learn the DEM.

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

This program deals with the classical **soft-sphere approach** of the DEM.
The main characteristics of this method are:

- It is assumed that the contact between the particles occurs through a small overlap between them.
- Each contact is evaluated through several time steps in an explicit integration scheme.
- Contact models relate the amount of overlap between neighboring particles to the forces between them.
- Other physical interactions (e.g. thermal) may also be related to the overlap between particles.
- The shape of the particles is kept unchanged during and after contacts. 

The program allows multiphysics simulations, counting on several interaction models in the following **analysis types**:

- Mechanical (solves the kinetics and kinematics of particles).
- Thermal (solves the temperature and heat flux of stationary particles).
- Thermo-mechanical (solves both mechanical and thermal analysis together).

Only two-dimensional (2D) models are handled by the program, with the following **element types**:

- Spherical particle (assuming that all spheres move on the same plane).
- Cylindrical particle (assuming an out-of-plane length).
- Rigid walls (straight and circular).

Almost all variables involved in the simulation process can be exported in one of the following **result types**:

- Text file.
- Graphs (plots and tables).
- Animations (scalar and vector results).

## Implementation Aspects

DEMLab is fully written in the [MATLAB][matlab_website] programming language,
and adopts the Object Oriented Programming (OOP) paradigm to offer modularity and extensibility.

The source code can run in any operating system where MATLAB can be installed
(the program is tested for version 2019b of MATLAB).

Because it is developed with a high-level interpreted programming language using serial processing,
code efficiency is not a priority and therefore only small to medium-scale problems should be simulated.

For large-scale problems, it is recommended to check the [DEM Application][demapp_link] and the [Thermal DEM Application][thermal_demapp_link]
of the [Kratos Multiphysics][kratos_link] framework.

## Instructions

### Input Files

There are three types of files that may be used as input for the program:

* **Model Parts (_.txt_)**: 

This text file is necessary for running a simulation and must always be accompanied by a _Project_ _Parameters_ file.
Its name must be indicated in the _Project_ _Parameters_ file.

It contains all the elements of the model (particles and walls) with their initial coordinates and geometry, as well as their grouping into model parts.

A tutorial on this file can be found on its [Wiki page][wiki_mparts_link].
Moreover, a [template][modelparts_link] of this file, with all the possible input options, is available.

* **Project Parameters (_.json_)**: 

This [JSON][json_link] file is necessary for running a simulation and must always be accompanied by a _Model_ _Parts_ file.
The name of the _Model_ _Parts_ file must be indicated in the Input Group ["ProblemData"][problem_data_link] of this file.

It contains all the parameters and options for the analysis and outputs, as well as the conditions applied to the model.

A tutorial explaining each input field of this file can be found on its [Wiki page][wiki_parameters_link].
Moreover, a [template][parameters_link] of this file, with all the possible input options, is available.

* **Results Storage (_.mat_)**: 

This binary file stores the results of a simulation.
It is generated only if requested in the Input Group ["Output"][output_link] of the _Project_ _Parameters_ file.

It can be loaded to show the results of previously run simulations, or used to restart a simulation from a saved stage.

### Running Simulations

To run a simulation, launch MATLAB and execute the script file [*main.m*][main_file_link] located inside the folder [*src*][src_folder_link].

A dialog box will pop up to select an appropriate _Project_ _Parameters_ file.
Multiple _Project_ _Parameters_ files can be selected to run simulations sequentially, as long as they are located in the same directory.

If the models and parameters are read correctly, the simulations are started and their progresses are printed in the MATLAB command window.

Sub-folders with the names of the simulations, plus the suffix _"out"_, are created to receive the output files with the requested results of each simulation.

### Loading Results

To load and show the results from previously run simulations, launch MATLAB and execute the script file [*main.m*][main_file_link] located inside the folder [*src*][src_folder_link].

A dialog box will pop up to select an appropriate _Results_ _Storage_ file.
Multiple _Results_ _Storage_ files can be selected to load and show results sequentially, as long as they are located in the same directory.

To restart a simulation from the stored results, place its _Results_ _Storage_ file in the same directory of the _Project_ _Parameters_ file and run the simulation.
The name of the _Results_ _Storage_ file must be the same of the simulation name indicated in the _Project_ _Parameters_ file.

### Testing

Recursive tests are available to verify that the program is working correctly and that the current results are matching with the reference results.
The reference results are stored in files with a _.pos_ extension.

To run the tests, launch MATLAB and execute the script file [*run_tests.m*][run_tests_link] located inside the folder [*tests*][tests_folder_link].

A dialog box will pop up to select the _Project_ _Parameters_ files of the tests to be run, located inside the sub-folder [*test_models*][test_models_link].
The result of each test is then printed in the MATLAB command window.

To generate or update the reference results, execute the script file [*update_results.m*][upd_tests_link] located inside the folder [*tests*][tests_folder_link]
and select the _Project_ _Parameters_ files of the tests to be updated, located inside the sub-folder [*test_models*][test_models_link].
It will run the selected tests and overwrite existing reference results.

## Examples

Sample models are available inside the folder [*examples*][examples_link].

They are separated into different sub-folders according to their analysis type,
and each example has its _Project_ _Parameters_ and _Model_ _Parts_ files, as well as some results in the output sub-folders.

<p align=center>
<img height="100.0%" width="31.0%" src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/examples/example_01.png">
&nbsp;&nbsp;
<img height="100.0%" width="34.0%" src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/examples/example_02.png">
&nbsp;&nbsp;
<img height="100.0%" width="25.0%" src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/examples/example_03.png">
</p>

<p align=center>
<img height="100.0%" width="30.0%" src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/examples/example_04.png">
<img height="100.0%" width="33.0%" src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/examples/example_05.png">
<img height="100.0%" width="33.0%" src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/examples/example_06.png">
</p>

## Documentation

Presentations on theoretical aspects of the DEM, showing the [contact force models][force_models_link] and the [heat transfer models][heat_models_link] implemented in the program,
are available inside the folder [*help*][help_folder_link].

The OOP classes of the program are documented in [UML diagrams][uml_link] and their codes in HTML files, located inside the folder [*html*][html_folder_link].
These files can be browsed on their [Wiki page][wiki_html_link].

Tutorials explaining all the options of the program that can be added to the input files (_Model_ _Parts_ and _Project_ _Parameters_)
can also be found on the [Wiki page][wiki_link].

## How to Contribute

Please check the [contribution guidelines][contribute_link].

## How to Cite

Rangel, R. L. (2022). DEMLab: Discrete Element Method Laboratory (1.0.0). Zenodo. https://doi.org/10.5281/zenodo.6509866

## Authorship

- **Rafael Rangel** (<rrangel@cimne.upc.edu>)

International Center for Numerical Methods in Engineering ([CIMNE][cimne_website]) 
and
Polytechnic University of Catalonia ([UPC BarcelonaTech][upc_website])

<p float="left">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/logos/logo_cimne.png" width="350"/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/logos/logo_upc.png" width="350"/> 
</p>

## Acknowledgement

The program was initially developed under the context of the [MATHEGRAM project][mathegram_website],
a Marie Sklodowska-Curie Innovative Training Network of the European Union’s Horizon 2020 Programme H2020 under REA grant agreement No. 813202.

<p float="left">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://github.com/rlrangel/DEMLab/blob/master/docs/images/logos/logo_mathegram.png" width="600"/>
</p>

## License

DEMLab is licensed under the [MIT license][mit_license_link],
which allows the program to be freely used by anyone for modification, private use, commercial use, and distribution, only requiring preservation of copyright and license notices.
No liability and warranty are provided.

[matlab_website]:       https://www.mathworks.com/
[demapp_link]:          https://github.com/KratosMultiphysics/Kratos/tree/master/applications/DEMApplication
[thermal_demapp_link]:  https://github.com/KratosMultiphysics/Kratos/tree/master/applications/ThermalDEMApplication
[kratos_link]:          https://github.com/KratosMultiphysics/Kratos
[json_link]:            https://www.json.org/
[wiki_parameters_link]: https://github.com/rlrangel/DEMLab/wiki/Project-Parameters-File
[wiki_mparts_link]:     https://github.com/rlrangel/DEMLab/wiki/Model-Parts-File
[wiki_link]:            https://github.com/rlrangel/DEMLab/wiki
[wiki_html_link]:       https://github.com/rlrangel/DEMLab/wiki/Classes-Documentation
[parameters_link]:      https://github.com/rlrangel/DEMLab/blob/master/docs/help/ProjectParameters_template.json
[modelparts_link]:      https://github.com/rlrangel/DEMLab/blob/master/docs/help/ModelParts_template.txt
[problem_data_link]:    https://github.com/rlrangel/DEMLab/wiki/Project-Parameters-File#problemdata
[output_link]:          https://github.com/rlrangel/DEMLab/wiki/Project-Parameters-File#output
[main_file_link]:       https://github.com/rlrangel/DEMLab/blob/master/src/main.m
[src_folder_link]:      https://github.com/rlrangel/DEMLab/tree/master/src
[run_tests_link]:       https://github.com/rlrangel/DEMLab/blob/master/tests/run_tests.m
[upd_tests_link]:       https://github.com/rlrangel/DEMLab/blob/master/tests/update_results.m
[tests_folder_link]:    https://github.com/rlrangel/DEMLab/tree/master/tests
[test_models_link]:     https://github.com/rlrangel/DEMLab/tree/master/tests/test_models
[examples_link]:        https://github.com/rlrangel/DEMLab/tree/master/examples
[contribute_link]:      https://github.com/rlrangel/DEMLab/blob/master/CONTRIBUTING.md
[cimne_website]:        https://www.cimne.com/
[upc_website]:          https://camins.upc.edu/
[mathegram_website]:    https://www.surrey.ac.uk/mathegram
[mit_license_link]:     https://choosealicense.com/licenses/mit/
[force_models_link]:    https://github.com/rlrangel/DEMLab/blob/master/docs/help/DEM_ContactForceModels.pdf
[heat_models_link]:     https://github.com/rlrangel/DEMLab/blob/master/docs/help/DEM_HeatTransferModels.pdf
[help_folder_link]:     https://github.com/rlrangel/DEMLab/tree/master/docs/help
[uml_link]:             https://www.uml.org/
[html_folder_link]:     https://github.com/rlrangel/DEMLab/tree/master/docs/html