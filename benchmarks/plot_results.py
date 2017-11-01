#!/usr/bin/env python

from __future__ import division, print_function

import glob
import re
import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

sns.set(style="whitegrid")

def load_results():
    all_dfs = []

    for f in sorted(glob.glob("results/*.csv")):
        print(f)
        m = re.match("result_(\d+)_(.+)_(.+).csv", os.path.basename(f))
        if m is not None:
            print(m.groups(), m.group(1))
            N = int(m.group(1))
            implementation = m.group(2)
            category = m.group(3)
            df = pd.read_csv(f, sep=";", header=None)
            df = df.rename(columns={0: "dtype"})
            df = df.melt(id_vars=["dtype"], var_name="iteration", value_name="runtime")
            df["implementation"] = implementation
            df["category"] = category
            all_dfs.append(df)

    df = pd.concat(all_dfs)
    return df


def plot(df, category):
    fig = plt.figure(figsize=(10, 8))
    """
    sns.violinplot(
        x="implementation", y="runtime", hue="dtype",
        data=df,
        inner="points",
        linewidth=0.5,
        #width=1.0
    )
    """
    """
    sns.violinplot(
        y="implementation", x="runtime", hue="dtype",
        data=df,
        linewidth=0.2,
    )
    """
    sns.stripplot(
        hue="implementation", y="runtime", x="dtype",
        data=df,
        size=6,
        linewidth=0.5,
        alpha=0.4,
        jitter=True,
        dodge=True,
        #inner="points",
        #width=1.0
    )
    plt.title(category)
    #plt.grid()
    #sns.despine(left=True, bottom=True)
    #plt.xscale("log")
    plt.ylabel("runtime [ms]")
    plt.savefig("results/plot_{}.png".format(category), dpi=120)


def plot_all():
    df = load_results()

    categories = df["category"].unique()
    for category in categories:
        sub_df = df.loc[df["category"] == category, :]
        plot(sub_df, category)
        #import IPython; IPython.embed()


if __name__ == "__main__":
    plot_all()