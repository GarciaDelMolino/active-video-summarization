/*
 * Xavier Boix Bosch
 * 6/5/09 second version
 */

#include <stdio.h>
#include <fstream>
#include <cctype>
#include "kgraph.h"
#include "kgraph.cpp"
#include "TRW/MRFEnergy.h"
#include "TRW/typeGeneral.h"
//#include <omp.h>

#define PARALLEL 8

int main(int argc, char **argv){

if (argc!=2) {
        printf("Error: call mrf <#frame>");
        return 0;
}

//int num_frames=atoi(argv[1]);
int num_image=atoi(argv[1]);
//#pragma omp parallel for num_threads(PARALLEL)
//for(int k=0;k<num_frames;k++){    
    
	MRFEnergy<TypeGeneral>* mrf;
	MRFEnergy<TypeGeneral>::NodeId* nodes;
	MRFEnergy<TypeGeneral>::Options options;
	TypeGeneral::REAL energy;
    
	double num_labels, num_nodes;
    char cad[100];
    sprintf(cad,"./tmp%d.lcl",num_image);
    
	FILE *p = fopen(cad,"rb");
	fread(&num_labels,sizeof(double),1,p);
	fread(&num_nodes,sizeof(double),1,p);

	mrf = new MRFEnergy<TypeGeneral>(TypeGeneral::GlobalSize(num_labels));
	nodes = new MRFEnergy<TypeGeneral>::NodeId[(int)num_nodes];
	
	double **c=new double * [(int)num_nodes];
    

	for(int i=0; i<num_nodes;i++){
        c[i]=new double[(int)num_labels];
		fread(c[i],sizeof(double),num_labels,p);
		nodes[i]=mrf->AddNode(TypeGeneral::LocalSize(num_labels), TypeGeneral::NodeData(c[i]));
	}
	
	fclose(p);
	
    
    
    sprintf(cad,"./tmp%d.cnn",num_image);          
	p=fopen(cad,"rb");
	
    
    
            
	double num_connections;
	fread(&num_connections,sizeof(double),1,p);

    double **V_tmp=new double * [(int) num_connections];
    
	
	double iNode1, iNode2, obs;
	for(int i=0;i<(int)num_connections;i++){//Set connections
		fread(&iNode1,sizeof(double),1,p);
		fread(&iNode2,sizeof(double),1,p);
        
        
       		 V_tmp[i]=new double[(int)(num_labels*num_labels)];
        	fread(V_tmp[i],sizeof(double),num_labels*num_labels,p);
        
		mrf->AddEdge(nodes[(int)iNode1-1],nodes[(int)iNode2-1], TypeGeneral::EdgeData(TypeGeneral::GENERAL,V_tmp[i]));
	}

	fclose(p);


	//////////////////////// BP algorithm ////////////////////////
	mrf->ZeroMessages(); // in general not necessary - it may be faster to start 
	                     // with messages computed in previous iterations

	options.m_iterMax = 5; // maximum number of iterations
	int a=mrf->Minimize_BP(options, energy);

        sprintf(cad,"./tmp%d.out",num_image);
	    p=fopen(cad, "wb");
	    int temp;
	    for(int i=0; i<num_nodes;i++){
	    	temp=(int)(mrf->GetSolution(nodes[i]));
	    	fwrite(&temp,sizeof(int),1,p);
	    }

	double* temp_p;
	 for(int i=0; i<num_nodes;i++){
              temp_p=(mrf->GetProb(nodes[i]));
              for (int j=0; j<(int) num_labels;j++)
                fwrite(&temp_p[j],sizeof(double),1,p);
            }



		fwrite(&(energy),sizeof(double),1,p);
fwrite(&(a),sizeof(int),1,p);
	    //printf("\n%d",(int)(mrf->getLabel(conn->getSize()-1)));
	    fclose(p);
        
        for(int i=0;i<(int)num_nodes;i++)
            delete [] c[i];
        
for(int i=0;i<(int)num_connections;i++)
    delete [] V_tmp[i];
    
            delete [] V_tmp;


            delete [] c;
	delete nodes;
	delete mrf;
//}
	return 0;
}
