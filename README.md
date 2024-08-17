MakeMathML creates a MathML output of the text file passed to this command line program as the first argument.  
Also the set of input equations in the input file are evaluated and produce an output for each line terminated with a ";".

For example the following input file:

~~~
let a = 2; let b = a+3;
let t = true;
let p2 = pi/2;
let t = 2;
a + 2*b - 3;
a & b;
2^b;
asin(sin(a));
sqrt(2+a^2);
log(1000);
ln(exp(3));
b²;
~(b+c);
10!
~~~

produces this output:

~~~
Parsing
Proc 
Block(
  a = 2.0  => 2.0
  b = (a ADD 3.0)  => 5.0
  t = true  => 1.0
  p2 = (pi DIV 2.0)  => 1.5707963267948966
  t = 2.0  => 2.0
  ((a ADD (2.0 MUL b)) SUB 3.0)  => 9.0
  (a AND b)  => 0.0
  (2.0 POW b)  => 32.0
  Built-in asin(Built-in sin(a))  => 1.1415926535897933
  Built-in sqrt((2.0 ADD (a POW 2.0)))  => 2.449489742783178
  Built-in log(1000.0)  => 3.0
  Built-in ln(Built-in exp(3.0))  => 3.0
  SQR b  => 25.0
  NOT (b ADD c)  => -6.0
  FACT 10.0  => 3628800.0
)

<!DOCTYPE html>
<html>
<body>
<p><math>
<mrow>
<mi>a</mi>
<mo>=</mo>
<mn>2</mn>
</mrow>
</math></p>

<p><math>
<mrow>
<mi>b</mi>
<mo>=</mo>
<mi>a</mi>
<mo>+</mo>
<mn>3</mn>
</mrow>
</math></p>

<p><math>
<mrow>
<mi>t</mi>
<mo>=</mo>
<mo>true</mo>
</mrow>
</math></p>

<p><math>
<mrow>
<mi>p2</mi>
<mo>=</mo>
<mfrac>
<mi>&pi;</mi>
<mn>2</mn>
</mfrac>
</mrow>
</math></p>

<p><math>
<mrow>
<mi>t</mi>
<mo>=</mo>
<mn>2</mn>
</mrow>
</math></p>

<p><math>
<mrow>
<mi>a</mi>
<mo>+</mo>
<mn>2</mn>
<mo>&InvisibleTimes;</mo>
<mi>b</mi>
<mo>&minus;</mo>
<mn>3</mn>
</mrow>
</math></p>

<p><math>
<mrow>
<mi>a</mi>
<mo>&amp;</mo>
<mi>b</mi>
</mrow>
</math></p>

<p><math>
<mrow>
<msup>
<mn>2</mn>
<mi>b</mi>
</msup>
</mrow>
</math></p>

<p><math>
<mrow>
<msup>
<mi>sin</mi>
<mn>-1</mn>
</msup>
<mo>(</mo>
<mi>sin</mi>
<mo>(</mo>
<mi>a</mi>
<mo>)</mo>

<mo>)</mo>

</mrow>
</math></p>

<p><math>
<mrow>
<msqrt>
<mn>2</mn>
<mo>+</mo>
<msup>
<mi>a</mi>
<mn>2</mn>
</msup>
</msqrt>
</mrow>
</math></p>

<p><math>
<mrow>
<msub>
<mi>log</mi>
<mn>10</mn>
</msub>
<mo>(</mo>
<mn>1000</mn>
<mo>)</mo>

</mrow>
</math></p>

<p><math>
<mrow>
<mi>ln</mi>
<mfenced>
<mrow><msup>
<mi>e</mi>
<mn>3</mn>
</msup>
</mrow></mfenced>
</mrow>
</math></p>

<p><math>
<mrow>
<msup>
<mi>b</mi>
<mn>2</mn>
</msup>
</mrow>
</math></p>

<p><math>
<mrow>
<mover>
<mrow>
<mi>b</mi>
<mo>+</mo>
<mi>c</mi>
</mrow>
<mo>&OverBar;</mo>
</mover>
</mrow>
</math></p>

<p><math>
<mrow>
<mn>10</mn>
<mo>!</mo>
</mrow>
</math></p>

</html>
</body>

Parsed correctly
Program ended with exit code: 0
~~~

The MathML output can be interpreted by most html browsers and produces the following:

![Screenshot 2024-08-17 at 3 05 18 PM](https://github.com/user-attachments/assets/661b82a0-9fa1-4e98-92bb-cb43a2477689)
![Screenshot 2024-08-17 at 3 06 55 PM](https://github.com/user-attachments/assets/4bb5f003-ac0e-4c97-9f77-265bf71ee759)


