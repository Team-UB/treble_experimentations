Team (UB) Modded Rom

Getting Started

To get started with Android/Team (UB), you'll need to get familiar with Git and Repo.

To initialize your local repository using the Team-UB trees, use a command like this:

repo init -u git://github.com/Team-UB/android.git -b TUB-Pie


Then to sync up:
----------------
bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags


Finally to build:
-----------------
bash
. build/envsetup.sh
lunch tub_device_codename-userdebug
mka tub -j$(nproc --all)


Building Treble Rom for S10/S10+/S10 5G/Note 10/Note 10+/Note 10+ 5G
------------------------------
mkdir tub; cd tub

git clone https://github.com/Team-UB/treble_experimentations

bash ../treble_experimentations/build-dakkar.sh tub arm64-aonly-gapps-nosu-user

