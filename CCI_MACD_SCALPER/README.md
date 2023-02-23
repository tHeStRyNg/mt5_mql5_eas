### CCI EMA MACD SCALPER

#### Strategy tested on EURUSD pair, and seems to work best on M15 period.

#### Indicators used:

- EMA (default period 30)
- CCI (default MA period 30)
- MACD (default MT5 settings)

### STRATEGY:

#### For BUY orders: 

- The candle must close ABOVE the EMA
- The CCI indicator must cross the 0 level and go into the positive
- The MACD indicator must be below 0 and make a cross while below the 0 level

#### For SELL orders: 

- The candle must close above the EMA
- The CCI indicator must cross the 0 level and go into the positive
- The MACD indicator must be below 0 and make a cross while below the 0 level

#### Example
Backtested on MT5 with ```CCI_EMA_MACD_Scalper_config_v0.1.set```

![image](https://user-images.githubusercontent.com/118682909/220904333-c5e6c89c-dd34-4f50-a4bc-c8727b714782.png)

So the correlation between the ross of CCI UP, MACD and EMA spinned a BUY Position.
For the example we used the following settings which is a reflection of ```CCI_EMA_MACD_Scalper_config_v0.1.set```.

![image](https://user-images.githubusercontent.com/118682909/220904644-455150ff-9602-4e5c-a65e-c2e6d0e3b9f8.png)
