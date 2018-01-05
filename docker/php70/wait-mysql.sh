#!/usr/bin/env bash

while ! mysqladmin ping -h database -u root -proot --silent; do
    sleep 1
done
