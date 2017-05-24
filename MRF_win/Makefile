INTERFACES = block.h kgraph.h  ./TRW/MRFEnergy.h ./TRW/typeGeneral.h mrf.cpp
REALISATIONS = block.h kgraph.h maxflow.cpp kgraph.cpp  ./TRW/MRFEnergy.cpp ./TRW/minimize.cpp ./TRW/ordering.cpp ./TRW/treeProbabilities.cpp 
OBJECTS       = maxflow.o kgraph.o  ./TRW/MRFEnergy.o ./TRW/minimize.o ./TRW/ordering.o ./TRW/treeProbabilities.o 
CC = g++ -funroll-loops
LD = $(CC) -s
LDFLAGS = -L/usr/X11R6/lib
CLEAR= @clear
ECHO = @echo
EXECUTABLE =  mrf
INCLUDE = -I .
#CFLAG = -w -c -Wall -ansi -O3
#CFLAG        = -g -w -ggdb -Wno-write-strings 
CFLAG        = -g -Wall -fPIC  -ansi -pthread 
DIRS=  ./TRW




#CFLAG        = -O2

#
# objects
#

%.o : %.cpp
	$(ECHO) "Compiling $< -> $(<:.cpp=.o)"
	$(CC) $(INCLUDE) $(CFLAG) -c $< -o $(<:.cpp=.o)

#
# binaries
#

$(EXECUTABLE) : $(OBJECTS)
	$(ECHO) "Linking"
	$(CC) $(CFLAG) $(LDFLAGS) $(OBJECTS) mrf.cpp -o $(EXECUTABLE) 


all : $(EXECUTABLE)

clr :
	$(ECHO) "Cleaning..."
	$(RM) *.o
	$(RM) ./TRW/*.o
	$(RM) *.mex*
	$(RM) $(EXECUTABLE)
	$(ECHO) "Cleaning over"

clean : clr
