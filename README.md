# SV-HotSpot


# Conda Installation

This package is available as conda package.  To install it via `conda`, try the following:

```bash
# create and activate a conda environment
conda create --yes --prefix /path/to/conda/environment
conda activate /path/to/conda/environment

# install sv-hotspot via conda
conda install --yes \
    --channel bioconda \
    --channel conda-forge \
    --channel https://raw.githubusercontent.com/eteleeb/SV-HotSpot/conda-channel/channel/  \
    --channel default \
    sv-hotspot

# test out installation
which sv-hotspot.pl  # should be /path/to/conda/environment/bin/sv-hotspot.pl
sv-hotspot.pl --help

# <do stuff with sv-hotspot>

# get out of conda environment
conda deactivate

# remove the conda environment
rm -rf /path/to/conda/environment
