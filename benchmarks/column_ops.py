#!/usr/bin/env python

from __future__ import division, print_function

import numpy as np
import pandas as pd
import sys
import time
import gc


class TimedContext(object):

    def __init__(self):
        self.runtime = None

    def __enter__(self):
        gc.collect()
        self.t1 = time.time()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.t2 = time.time()
        self.runtime = (self.t2 - self.t1) * 1000
        # print("{:<60s} {:6.3f} ms".format(self.label, runtime))


def bench_zeros(dtype, N):
    with TimedContext() as ctx:
        data = np.zeros(N, dtype=dtype)
    assert len(data) == N
    return ctx.runtime


def bench_ones(dtype, N):
    with TimedContext() as ctx:
        data = np.ones(N, dtype=dtype)
    assert len(data) == N
    return ctx.runtime


def bench_range(dtype, N):
    with TimedContext() as ctx:
        data = np.arange(0, N, dtype=dtype)
    assert len(data) == N
    return ctx.runtime


def bench_sum(dtype, N):
    data = np.zeros(N, dtype)
    with TimedContext() as ctx:
        sum_val = data.sum()
    assert sum_val > -1
    return ctx.runtime


def bench_max(dtype, N):
    data = np.zeros(N, dtype)
    with TimedContext() as ctx:
        max_val = data.max()
    assert max_val > -1
    return ctx.runtime


def run_benchmark_repeated(benchmark, label, N, iterations, dtypes, result_file):
    print(" *** Benchmark: {}".format(label))
    for dtype in dtypes:
        runtime_sum = 0.0
        runtime_min = None
        runtime_max = None
        all_runtimes = []
        for i in xrange(iterations):
            runtime = benchmark(dtype, N)
            all_runtimes.append(runtime)
            runtime_sum += runtime
            if runtime < runtime_min or runtime_min is None:
                runtime_min = runtime
            if runtime > runtime_max or runtime_max is None:
                runtime_max = runtime
        runtime_avg = runtime_sum / iterations
        # echo label, ": ", runtime
        print(
            "{:<60s} {:6.3f} ms    {:6.3f} ms    {:6.3f} ms".format(
                dtype.__name__, runtime_min, runtime_avg, runtime_max
            )
        )
        result_row = [dtype.__name__] + [str(rt) for rt in all_runtimes]
        result_file.write(";".join(result_row) + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("ERROR: Expected argument N.")
        sys.exit(1)
    else:
        N = int(sys.argv[1])

    dtypes = [np.int16, np.int32, np.int64, np.float32, np.float64]

    benchmarks = [
        (bench_zeros, "zeros"),
        (bench_ones, "ones"),
        (bench_range, "range"),
        (bench_sum, "sum"),
        (bench_max, "max"),
    ]

    for benchmark, label in benchmarks:
        filename = "results/result_{}_pandas_{}.csv".format(N, label)
        with open(filename, "w") as result_file:
            run_benchmark_repeated(
                benchmark, label, N, 100, dtypes, result_file
            )
