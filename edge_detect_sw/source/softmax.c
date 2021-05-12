#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <math.h>

#define high_threshold 48
#define low_threshold 12
//macros from lecture

	#define BITS            10
   #define QUANT_VAL       (1 << BITS)
   #define QUANTIZE_F(f)   (int)(((float)(f) * (float)QUANT_VAL))
   #define DEQUANTIZE_F(i) (float)((float)(i) / (float)QUANT_VAL)
   #define QUANTIZE_I(i)   (int)((int)(i) * (int)QUANT_VAL)
   #define DEQUANTIZE(i)   (int)((int)(i) / (int)QUANT_VAL)

//what I know:
//range of in[i] - alpha can be between 0 and -10(largest value for alpha is 10, smallest value for in[i] is 0)
//range of my_exp is going to depend on range of in

int my_exp[100];
//float representation
void softmax_f(float in[], float out [],
    const unsigned size) {

    //unsigned size = ih * iw * id;
    unsigned i;
    float denominator = 0.0;

    float alpha = in[0];
    
    //find max val in input image
    for( i=1; i < size; ++i) {
        if(in[i] > alpha)
            alpha = in[i];
    }

   printf("alpha: %8.4f\n",alpha);
//exp will be done using a lookup table 
    for( i=0; i < size; ++i) {
        out[i] = exp(in[i] - alpha);
        denominator += out[i];
    }
    printf("denominator: %8.4f\n",denominator);

    for( i=0; i < size; ++i) {
       //printf("out_val_before: %8.4f ",out[i]);
       out[i] /= denominator;
       //printf("out_val_after: %8.4f\n",out[i]);
        
    }
    
}

//fixed point
//NEED TO KNOW MIN AND MAX OF SOFTMAX FUNCTION
//find range of input to exponential
//leave 2 bits at top, 6 bits for floating point

void softmax_i(int in[], int out [],
    const unsigned size) {

    //unsigned size = ih * iw * id;
    unsigned i;
    int denominator = 0;

    int alpha = in[0];
    
    //find max val in input image
    for( i=1; i < size; ++i) {
        if(in[i] > alpha)
            alpha = in[i];
    }

    printf("alpha: %i\n",alpha);


   //printf("alpha: %8.4f\n",alpha);
//exp will be done using a lookup table 
    for( i=0; i < size; ++i) {
        out[i] = my_exp[in[i] - alpha]; //+ RANGE_MIN];
        denominator += out[i];
    }
    printf("denominator: %8.4f\n",denominator);

    for( i=0; i < size; ++i) {
       //printf("out_val_before: %8.4f ",out[i]);
       out[i] = QUANTIZE_I(out[i]) / denominator;
       //printf("out_val_after: %8.4f\n",out[i]);
    }
    
}


/*

float relu_op(float val) {
   if(val < 0.0){
      val = 0.0;
   }
   return val;
}
//size is width*height of img
void relu(float in[], float out[], const int size) {
    unsigned i;

    for( i=0; i < size; ++i) {
        out[i] = relu_op(in[i]);
    }
}
*/
double randMToN(double M, double N)
{
    return M + (rand() / ( RAND_MAX / (N-M) ) ) ;  
}

void main () { 
   float in[100];
   float out[100];
   int in2[100];
   int out2[100];
   for(int i=0;i<100;i++) {
         in[i] = randMToN(0.0,10.0);
         in2[i] = QUANTIZE_F(in[i]);
         printf("in: %f, in2: %i\n",in[i],in2[i]);
   }
   
   printf("------------------------------------\n");
   printf("STARTING EXP QUANTIZATION\n");

   printf("SMALLEST_QUANTIZE_VAL: %i\n", QUANTIZE_F(10.0));
   printf("LARGEST_QUANTIZE_VAL: %i\n",QUANTIZE_F(0.0));
   

//Possible values I can have for exp(i) are :
//exp(-10.0), exp(0)

   for(int i= 0; i < 100; i++) {
       my_exp[i] = QUANTIZE_F(exp(i/10 - 10));
       printf("i: %i,table_val: %i\n",i,my_exp[i]);
    }

   softmax_f(in,out,100);

   printf("------------------------------------\n");
   printf("STARTING SOFTMAX_QANTIZATION_VERSION\n");

   softmax_i(in2,out2,100);
   for(int i=0;i<100;i++) {
       float f2 = DEQUANTIZE_F(out2[i]);
       float f1 = out[i];
       float err = f2 - f1;
      printf("in_val: %8.4f, out_val1: %8.4f out_val2: %8.4f diff: %8.4f \n",in[i],f1,f2,err);
   }

}
