# Zig-TFlite-MNIST

MNIST with Zig x Tensorflow Lite
![スクリーンショット 2022-08-18 16 43 04](https://user-images.githubusercontent.com/1560508/185437509-0afdc96b-03ef-4fc1-8a87-88d6c2f1d361.png)

Tested on
- Machine: Mac Mini 2021
- Chip: Apple M1
- Memory: 16GB
- OS: macOS 12.4（21F79）
- Zig: 0.10.0-dev.3414+4c750016e

## How to execute

At first, download MNIST data in png format from [here](https://www.kaggle.com/datasets/jidhumohan/mnist-png).

Then, install TFLite. You can read how to build TFLite from [here](https://github.com/mattn/zig-tflite#tensorflow-installation).

Finally, execute the commands below:

```sh
git clone https://github.com/ryoppippi/zig-tflite-mnist
zig build -Drelease-safe=true
./zig-out/bin/zig-tflite-mnist
```

## License

MIT

## Author

Ryotaro "Justin" Kimura (a.k.a. ryoppippi)



