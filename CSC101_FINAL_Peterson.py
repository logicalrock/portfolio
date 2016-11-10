#!/usr/bin/python3
#I decided to take out the big 'WP' for now.
#This is the author and class info
#########################################
#########################################
##                                     ##
## Author: William Peterson            ##
## Class: CSC 101                      ##
## Week: 15                            ##
## Assnment: Zoo Animals (Final_P1)    ##
## Date: 16 Dec 2015                   ##
##                                     ##
#########################################
#########################################

from random import randint
import random
import math
import time
import sys
import turtle

animal1 = None
cat1 = None
cat2 = None
bird1 = None
bird2 = None
lizard1 = None

class Animal:
    """
    Superclass of all animals
    
    """

    def __init__(self,name, legs, color, age):
    
        self.name = name
        self.legs = 0
        self.color = color
        self.age = age

    def __str__(self):
        output = "The {0} \nhas {1} legs and\nit is {2} in color\nand {3} years of age".format(
            self.name, self.legs, self.color, self.age)
        return output

class Cat(Animal):
    """
    cat
    
    """

    def __init__(self,name, legs, color, age, skin):
        super().__init__(name, legs,color, age)
        self.legs = 4
        self.skin = 'fur'
        return None       

    def __str__(self):
        parentOutput = super().__str__()
        output = "{}\nand has {} on it's skin".format(parentOutput, self.skin)
        return output

class Bird(Animal):
    """
    bird
    
    """

    def __init__(self,name, legs,color, age, skin):
        super().__init__(name, legs,color, age)
        self.legs = 2
        self.skin = 'feathers'
        return None


    def __str__(self):

        parentOutput = super().__str__()
        output = "{} \nand has {} on it's skin".format(parentOutput, self.skin)
        return output
        
class Lizard(Animal):
    """

    lizard
    
    """

    def __init__(self, name, legs, color, age, skin):
        super().__init__(name, legs, color, age)
        self.legs = 4
        self.skin = 'scales'
        return None
        
    def __str__(self):
        parentOutput = super().__str__()
        output = "{} \nand has {} on it's skin".format(parentOutput, self.skin)
        return output

animal1 = Animal('generic animal', 0, 'color', 0)

cat1 = Cat('tiger', '', 'orange with black stripes', 10,'')
cat2 = Cat('lion', '', 'tan', 15, '')

bird1 = Bird('parrot','', 'blue', 75, '')
bird2 = Bird('raven', '','black',100, '')

lizard1 = Lizard('gecko','', 'green', 2, '')


animalList = [cat1,cat2, bird1,bird2,lizard1]

for animals in animalList:
    print(animals)
    print()




