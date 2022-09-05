<head>
<style>
.myDiv {
  background-color: lightblue;
  text-align: left;
}
</style>
</head>

# Jupyter Notebook Setup

<div class="myDiv">
  <h2>Notes on setting up a Jupyter Notebook for Python, from Python installation to notebook export.</h2>
  <p>A.Nakamura</p>
  </div>

# Install Python

Download the latest version of Python from [Python.org](www.python.org/downloads).

## Installation Quick Checks

1. Python.exe: In the Windows Start menu, type 'py'. You should see the application. 
2. IDLE.bat: This is the default editor that's downloaded with Python. In the Windows Start menu, type 'IDLE'. You should see IDLE.bat appear. 

# Check For the Package Installer 

`pip` is Python's package installer and should be automatically installed with Python installations from [Python.org](python.org). To confirm that `pip` has been installed: 

1. Open python using the cmd window or IDLE.bat
2. Try to import pip. No error should display.

```
>>>import pip

```
Alternatively, from the command line, check the pip version. 

```
>py -m pip --version

```

## Install pip If Necessary

1. Download the [get-pip.py file](https://bootstrap.pypa.io/get-pip.py) 
2. Save a copy to the %USERPROFILE% (see below for folder naming conventions)
3. Run get-pip.py in Python

```
>py -m get-pip.py

```

4. Confirm installation (see above)

## "Basic" Packages 

### Most Commonly Used for Data Analysis

- **pandas**: Data manipulation, including reading/writing data from/to CSV and Excel files and SQL databases; reshaping, subsetting, aggregating, merging, and transforming datasets.
- **NumPy**: Math and array operations (adding, multiplyiing, reshaping); operations on time series; minimum/maximum (linear programming). Source functions for many key libraries. 
- **matplotlib**: This is the foundation for all Python visualization libraries. Used for creation of basic line plots, histograms, scatter plots, bar charts, etc. 
- **seaborn**: Graphical library for customizing statistical graphs. Use with `matplotlib` to reduce the amount of code. 
- **scikit-learn**: Running regression, classification, or other statistical analyses. More flexibility for visualization of complex relationships. 

### Tools for APIs and Natural Language Processing 

- **requests**: Enables Python to efficiently send HTTP requests (e.g., for APIs). Note that **urllib3** is a dependency for `requests`. 
- **NLTK**: Natural Language Toolkit, used for topic modeling, sentiment analysis and generally finding patterns in text beyond simple word clouds. 

### Nice to Haves

- **Pandoc**: Document conversion 
- **LaTeX**: Control styles, fonts, write mathematical formulas
- **Jupyter**: Presentation and documentation
 

### Python Libraries, Modules, and Packages

#### Module Basics

Script containing reusable code (e.g., function). For example, the following script that prints a project name can be saved as a module by saving the script with the `.py` extension (e.g., `atbl.py`). 

```
def atbl_header(projectname): 
    print("Based on sample data extracted from " + projectname + " records.")
    
def atbl_footer(fname, lname, path)
    print("See " + fname + " " + lname + "for more information about table source data, available here: " + path )
```

To use this module, just import the module in the python shell or notebook, and call the selected functions. 

```
import atbl

atbl.atbl_header("myproject")

<table object creation>

atbl.atbl_footer("Ann","Nakamura","c:\users\myusername\sampledata\")

```

Commonly used modules that come with the default installation of Python include
`os`, `datetime`, and `re`.  To see installed modules, submit the following command: 

```
help('modules') # all installed modules
help(__builtins__) # for built-in modules

```

#### Libraries and Packages
Generic terms for reusable code containing *collections* of related modules and packages/subpackages. 

## Installing Packages

```
>py -m install NumPy
```

To see which packages are installed, use the list function

```
>py -m pip list
```


# Creating Environmental Variables 

PATH environmental variables are Windows system variables, used in security control, that identify directories to be searched for specific commands, like Python commands run from the command prompt.

PATH environmental variables are called by placing the variable name between two percent signs. For example, %PATH% is an environmental variable that includes a list of folders (e.g., C:\Windows\), separated by semicolons.

## Folder naming conventions

To navigate in the command prompt, create new PATH variables, or direct pointers to files, you'll need to be able to map PATH variables to the the directory tree. 

- Root folder (%SystemDrive%): The highest directory in a given partition. On Windows, the main partition will likely be `c:\`. The "root" folder may be defined for particular tasks (e.g., installation).    
    - User folder: c:\users
    - User profile folder (%USERPROFILE%): Typically c:\user\username 

- sys.prefix path: the site-specific directory prefix where Python files are installed. Used with the `--prefix` argument to the configure script. See: [sys--System-specific parameters and functions](docs.python.org/3/library/sys.html) for more information. Find by issuing the following command at the command prompt (e.g., from your user profile folder): 

```>py -m site --user-site``` 

### New PATH variables to be created

- PY_HOME: Python Home path where the python executables live. Typically %USERPROFILE%\AppData\Local\Programs\Python\Python310

- PYTHONPATH: Where packages are actually installed (find a package and search for it using file explorer if uncertain)
    - Typically %USERPROFILE%\AppData\Local\Programs\Python\Python310\Lib\site-packages


# Installing Jupyter Notebook

## Launch Jupyter Notebook

Install and launch Jupyter Notebook from the command prompt:  

```

>py -m pip install jupyter

>py -m jupyter notebook

```

## Check Installation and Notebook Directory

Since Jupyter is a web application, the last command will open Jupyter Notebook in a new browser window. By default, the landing page will `localhost:8888/notebooks`, so nothing else can be running on this port. 

The notebook directory tree on the home PC should be relative to the user profile folder. To find the working directory in Python, import the `os` module (see [Miscellaneous operating system interfaces](https://docs.python.org/3/library/os.html)) and call the `os.getcwd()` function. Note that `getcwd()` is similar to `getwd()` in R. The `c` stands for current (i.e., current working directory). 

### Notes on Looping and Security 

Jupyter commands will be sent through your router, which will send commands back to your own machine's virtual server - kind of like calling yourself on your own phone. In a network, requests are sent through a combination of Transmission Control Protocol/Internet Protocol (TCP/IP) pairs that determine *how* and *where* messages are sent.  Each internet service provider (ISP) gets a range of IP addresses to allocate and certain IP addresses are reserved for special purposes, like the range of IP addresses reserved for local machines (127.0.0.0 - 127.255.255.255). 

When you open your browser and send a request to connect to an IP address, the TCP/IP tells the router to look at the first block of the IP address to figure out where to send the request.  If your IP address starts with `172`, for example (Google), your router knows you want to connect to the internet, forwards your request via your internet connection (provided by your ISP), which connects you to the appropriate web server. 

If your IP address starts with one of the special reserved blocks (`127`), your router does not send the request out to the internet. Instead, the request is kept locally and sent to back your own local machine (looping back). This is why it's possible to run Jupyter notebook without an internet connection. Posting your own content (not sharing) is as secure as your own computer is.  

For security information, see [Security in the jupyter notebook server](https://jupyter-notebook.readthedocs.io/en/stable/security.html). 



# Installing Pandoc and LaTex 

To convert the file to other formats, like PDF, control styling, and write and render math equations you need to install [Pandoc](https://pandoc.org) and [LaTex](https://www.latex-project.org) (pronounced LAY-tech). 

## Pandoc Installation

1. Download the [installer for Windows 64-bit](https://pandoc.org/installing.html). By default, the SetUp Wizard installs to %USERPROFILE%\AppData\Local\Pandoc\.
2. Click 'Finish'.
3. Restart PC.

## LaTex Installation (using a TeX distribution)
MiKTeX (pronounced MICK-tech) is an open source implementation of TeX, LaTeX, and related programs.

1. Go to the [Comprehensive TEX Archive Network](https://www.ctan.org/pkg/latex) and look up available TeX distributors.
2. Choose a TeX distribution option (e.g., [MiKTeX](https://miktex.org/about)).
3. Download the installer.
4. Run the SetUp executable. The distribution should include a version of LaTeX. 
5. Restart PC




# Test Notebook Rendering

The following code chunks import three libraries, create a series of x-y pairs, and plots a simple line graph. 



```python
import matplotlib.pyplot as plt
import numpy
from scipy.special import expit
```


```python
x = numpy.linspace(-6,6,50)
y = -expit(x)
plt.plot(x,y)
plt.text(0,-.5,'Midpoint')
plt.title("A Simple Graph")
plt.xlabel('Time points (x)') 
plt.ylabel('-sigmoid(x)') 
plt.show()
```

![](/efficiency_boosters/00_JupyterSetup/00_JupyterSetup_grph.png)<!-- -->

# Exporting 

Navigate to File > Download as...

- HTML
- LaTex[<sup>1</sup>](#fn1)
- RevealJS 
- PDF[<sup>2</sup>](#fn2) 

Alternatively, at the command prompt, type the following: 

```
>py -m nbconvert --to pdf MyFileName.ipynb # For PDF output. Replace 'pdf' by 'html' or other format as needed. 
```



# Exiting Jupyter

From the command line, enter ctrl+C.  

From the web interface, click on File > Close and Halt. 

# Footnotes
<sup>1</sup><span id="fn1"> Exports to LaTeX or PDF require installation of Pandoc and LaTeX</span>
<br>
<sup>2</sup><span id="fn2"> Special characters, like dollar signs, may cause the PDF rendering to fail. Playing around with the format (e.g., removing spaces, adding spaces, or line breaks) can sometimes resolve the issue.</span>
