

#include <stdio.h>
#include <fstream>
#include <cctype>
#include "kgraph.h"
#include "kgraph.cpp"
#include "TRW/MRFEnergy.h"
#include "TRW/typeGeneral.h"
#include "mex.h"


void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
                 const mxArray *prhs[])
{
  
  if (nrhs != 3) {
    mexErrMsgTxt("Error input");
  }

    
  MRFEnergy<TypeGeneral>* mrf;
  MRFEnergy<TypeGeneral>::NodeId* nodes;
  MRFEnergy<TypeGeneral>::Options options;
  TypeGeneral::REAL energy;
    
  double num_labels, num_nodes;

  double * lcl = mxGetPr(prhs[0]);

	

  double * cnn = mxGetPr(prhs[1]);

  double * opts = mxGetPr(prhs[2]);
  
  double num_connections;

	
  num_labels = lcl[0];
  num_nodes = lcl[1];
  num_connections = cnn[0];
  
  //mexPrintf("Num labels: %d \n  Num nodes: %d \n Num connections: %d \n Num iterations: %d \n", (int) num_labels, (int) num_nodes, (int) num_connections, (int) opts[0]);
  //mexPrintf("CNN: %d \n", (int) *cnn);
  //mexPrintf("LCL: %d \n", (int) *lcl);
	
	
	
    

  mrf = new MRFEnergy<TypeGeneral>(TypeGeneral::GlobalSize(num_labels));
  nodes = new MRFEnergy<TypeGeneral>::NodeId[(int)num_nodes];
  

  for(int i=0; i<num_nodes;i++){
    nodes[i]=mrf->AddNode(TypeGeneral::LocalSize(num_labels), TypeGeneral::NodeData(&(lcl[(int)(num_labels)*i+2])));
}
    
	
  double iNode1, iNode2, obs;
  int idx=1;
  for(int i=0;i<(int)num_connections;i++){//Set connections
    iNode1=cnn[idx++];
    iNode2=cnn[idx++];
    mrf->AddEdge(nodes[(int)iNode1-1],nodes[(int)iNode2-1], TypeGeneral::EdgeData(TypeGeneral::GENERAL,&(cnn[idx])));
    idx+= (int) (num_labels*num_labels);
  }
  



  //////////////////////// BP algorithm ////////////////////////
  mrf->ZeroMessages(); // in general not necessary - it may be faster to start 
  // with messages computed in previous iterations


  options.m_iterMax = (int) opts[0]; // maximum number of iterations
  int a=mrf->Minimize_BP(options, energy);


  plhs[0] = mxCreateDoubleMatrix((int) (num_nodes),1, mxREAL);
  plhs[1] = mxCreateDoubleMatrix((int) (num_nodes), (int)num_labels, mxREAL);
  plhs[2] = mxCreateDoubleMatrix(1, 1, mxREAL);
 
  double * oLabel = mxGetPr(plhs[0]);
  double * oProb =  mxGetPr(plhs[1]);
  double * oEnergy = mxGetPr(plhs[2]);
  
  for(int i=0; i<num_nodes;i++){
    oLabel[i]=(double)(mrf->GetSolution(nodes[i]));
//mexPrintf("label: %d \n", (int) oLabel[i]);
  }

  double* temp_p;
  for(int i=0; i<num_nodes;i++){
    temp_p=(mrf->GetProb(nodes[i]));
    for (int j=0; j<(int) num_labels;j++)
      oProb[j + i*((int)(num_labels))]=temp_p[j];
}

  oEnergy[0] = energy;

		
   
  delete nodes;
  delete mrf;

}
