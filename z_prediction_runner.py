import os
import sys

dry_run = '--dry-run' in sys.argv
local   = '--local' in sys.argv

if not os.path.exists("slurm_logs"):
    os.makedirs("slurm_logs")

if not os.path.exists("slurm_scripts"):
    os.makedirs("slurm_scripts")


networks_dir = '/om/user/wwhitney/deep-game-engine/networks/'
base_networks = {
    'angrand': networks_dir + 'angrand'
    }


# Don't give it a save name - that gets generated for you
jobs = [
        # A couple of quick tests
        {
            'coder': 'default',
            'dim_hidden': 40,
            'datasetdir': 'dataset',
            'num_train_batches': 10,
            'num_test_batches': 10,
            'learning_rate': '-0.001',
            'epoch_size': 5,
            'tests_per_epoch': 5,
        },

        # the real jobs
        # {
        #     'coder': 'angrand',
        #     'datasetdir': 'dataset-copied',
        #     'num_train_batches': 10000,
        #     'num_test_batches': 1000,
        #     'learning_rate': '-0.001'
        # },
        # {
        #     'coder': 'angrand',
        #     'datasetdir': 'dataset-copied',
        #     'num_train_batches': 10000,
        #     'num_test_batches': 1000,
        #     'learning_rate': '-0.0001'
        # },
        # {
        #     'coder': 'angrand',
        #     'datasetdir': 'dataset-copied',
        #     'num_train_batches': 10000,
        #     'num_test_batches': 1000,
        #     'learning_rate': '-0.00001',
        # },
        # {
        #     'coder': 'angrand',
        #     'datasetdir': 'dataset-copied',
        #     'num_train_batches': 10000,
        #     'num_test_batches': 1000,
        #     'learning_rate': '-0.000001'
        # },


    ]

if dry_run:
    print "NOT starting jobs:"
else:
    print "Starting jobs:"

for job in jobs:
    jobname = "z_prediction"
    flagstring = ""
    for flag in job:
        if isinstance(job[flag], bool):
            if job[flag]:
                jobname = jobname + "_" + flag
                flagstring = flagstring + " --" + flag
            else:
                print "WARNING: Excluding 'False' flag " + flag
        elif flag == 'import':
            imported_network_name = job[flag]
            if imported_network_name in base_networks.keys():
                network_location = base_networks[imported_network_name]
                jobname = jobname + "_" + flag + "_" + str(imported_network_name)
                flagstring = flagstring + " --" + flag + " " + str(network_location)
            else:
                jobname = jobname + "_" + flag + "_" + str(job[flag])
                flagstring = flagstring + " --" + flag + " " + str(job[flag])
        else:
            jobname = jobname + "_" + flag + "_" + str(job[flag])
            flagstring = flagstring + " --" + flag + " " + str(job[flag])
    flagstring = flagstring + " --name " + jobname

    jobcommand = "th z_prediction_main.lua" + flagstring
    with open('slurm_scripts/' + jobname + '.slurm', 'w') as slurmfile:
        slurmfile.write("#!/bin/bash\n")
        slurmfile.write("#SBATCH --job-name"+"=" + jobname + "\n")
        slurmfile.write("#SBATCH --output=slurm_logs/" + jobname + ".out\n")
        slurmfile.write("#SBATCH --error=slurm_logs/" + jobname + ".err\n")
        slurmfile.write(jobcommand)

    # if not os.path.exists(jobname):
    #     os.makedirs(jobname)

    # with open(jobname + '/generating_parameters.txt', 'w') as paramfile:
    #     paramfile.write(str(job))

    print(jobcommand)
    if local and not dry_run:
        # os.system(jobcommand + ' 2> slurm_logs/' + jobname + '.err 1> slurm_logs/' + jobname + '.out &')
        os.system(jobcommand)

    else:
        with open('slurm_scripts/' + jobname + '.slurm', 'w') as slurmfile:
            slurmfile.write("#!/bin/bash\n")
            slurmfile.write("#SBATCH --job-name"+"=" + jobname + "\n")
            slurmfile.write("#SBATCH --output=slurm_logs/" + jobname + ".out\n")
            slurmfile.write("#SBATCH --error=slurm_logs/" + jobname + ".err\n")
            slurmfile.write(jobcommand)

        if not dry_run:
            os.system("sbatch -N 1 -c 1 --gres=gpu:1 -p gpu --time=6-23:00:00 slurm_scripts/" + jobname + ".slurm &")








