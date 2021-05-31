#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <math.h>

#define high_threshold 48
#define low_threshold 12
//macros from lecture


//how many fractional bits??
	#define BITS            10
   #define QUANT_VAL       (1 << BITS)
   #define QUANTIZE_F(f)   (int)(((float)(f) * (float)QUANT_VAL))
   #define DEQUANTIZE_F(i) (float)((float)(i) / (float)QUANT_VAL)
   #define QUANTIZE_I(i)   (int)((int)(i) * (int)QUANT_VAL)
   #define DEQUANTIZE(i)   (int)((int)(i) / (int)QUANT_VAL)

//what I know:
//range of in[i] - alpha can be between 0 and -10(largest value for alpha is 10, smallest value for in[i] is 0)
//range of my_exp is going to depend on range of in

int my_exp[4096];

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
    for( i=0; i < size; ++i) {
        out[i] = exp(in[i] - alpha);
        denominator += out[i];
        //printf("mval,out[i],curr_denom = %8.4f : %8.4f :%8.4f\n",in[i]-alpha,out[i],denominator);
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

    //printf("alpha_int: %i\n",alpha);

//exp will be done using a lookup table 
//TO DO: CONVERT TO UNSIGNED SHORT AND USE THAT FOR LOOKUP OF MY_EXP
    for( i=0; i < size; ++i) {
        int mval = in[i] - alpha;
        unsigned short lookup_val = (mval) & 0x0fff;
        //if we are less than -4.0(when we have 1%error) just set out[i] to 0
        //less than 50% just 0 it out
        if(mval == 0) {
            out[i] = 1024;
            printf("c");//QUANTIZE_I(1); //QUANTIZE_I(1) = 1024 (1*2^10)??
        }
        else if(mval < 0xfffff000) {
            printf("a");
            out[i] = 0;
        }
        else {
            printf("b");
            out[i] = my_exp[lookup_val]; 
        }
        float x = DEQUANTIZE_F(mval);
        //printf("val,val_hex,out_val,dequantized,actual_v: %i : %0.4x : %0.4x : %6.10f : %6.10f : %6.10f\n",mval,lookup_val,out[i], DEQUANTIZE_F(out[i]),x,exp(x));
        denominator += out[i];
        //printf("%6.10f : %6.10f : %6.10f\n",DEQUANTIZE_F(out[i])-exp(x),DEQUANTIZE_F(out[i]),exp(x));
        printf("mval,lookup_val,out[i],curr_denom = %0.8x : %0.4x : %0.8x :%0.4x\n",mval,lookup_val,out[i],denominator);
    }
    printf("denominator: %0.4x\n",denominator);

    for( i=0; i < size; ++i) {
        //if out[i] = 0 do nothing, otherwise run division
       out[i] = QUANTIZE_I(out[i]) / denominator;
       printf("out = %0.4x\n",out[i]);
    }
    
}

double randMToN(double M, double N)
{
    return M + (rand() / ( RAND_MAX / (N-M) ) ) ;  
}


void main () { 
   float in[100];
   float out[100];
   int in2[100];
   int out2[100];
   //max val: 10240 (14 bits needed at least)
   printf("localparam[15:0] random_test_vals[0:99] = '{");
   for(int i=0;i<100;i++) {
        in[i] = randMToN(0.0,10.0);
        in2[i] = QUANTIZE_F(in[i]);
        printf("16'h%0.4x, ",in2[i]);
        if(i%10 == 0) {
            printf("\n");
        }
   }
   printf("};\n");

   //just to make sure the values are the same across iterations:
   /*
   printf("[");
   for(int i=0;i<100;i++) {
       printf("%i, ",in2[i]);
   }
   printf("]\n");
   */
   
   //Represent i(input vals) as short(16 bits)
   //6.10 6 whole, 10 bits for fractional
   //goes from DEQUANTIZE_F(61440) to DEQUANTIZE_F(65536)
   //i.e. goes from -4 to 0, which is all we need, bc only lookup negative vals(x - alpha), and e^-4 = .018, p close to 0
   printf("localparam[11:0] exp_arr [0:4095]= '{");
   for(int i=61440; i <= 65536; i++) {
       short v = (short) i % 65536;
       float f = DEQUANTIZE_F(v);
       float e = exp(f);
       my_exp[i & 0x0fff] = (short) QUANTIZE_F(e); 
       int mval = my_exp[i & 0x0fff];
       printf("12'h%0.3x, ",mval); //vals in this array are 16 bits??
       if(i%100 == 0) {
           printf("\n");
       }
       //printf("%i : %04x : %6.10f : %6.10f : %0.4x : %6.10f\n",i,v,f,e,mval,DEQUANTIZE_F(mval));
   }
   printf("};\n");



//Possible values I can have for exp(i) are :
//exp(-10.0), exp(0)

   softmax_f(in,out,100);

   printf("------------------------------------\n");
   printf("STARTING SOFTMAX_QANTIZATION_VERSION\n");

   softmax_i(in2,out2,100);

   printf("------------------------------------\n");
   printf("COMPUTING ERRORS\n");
   for(int i=0;i<100;i++) {
       float f2 = DEQUANTIZE_F(out2[i]);
       float f1 = out[i];
       float err = (f2 - f1);
      printf("in_val: %8.4f, out_val1: %8.4f out_val2: %8.4f diff: %8.4f \n",in[i],f1,f2,err);
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