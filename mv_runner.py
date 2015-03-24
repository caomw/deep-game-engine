import os

if not os.path.exists("slurm_logs"):
    os.makedirs("slurm_logs")

if not os.path.exists("slurm_scripts"):
    os.makedirs("slurm_scripts")


networks_dir = '/om/user/wwhitney/facegen_networks/'
base_networks = {
        'picasso':      networks_dir + 'picasso',
        'braque':       networks_dir + 'braque',
        'brunelleschi': networks_dir + 'brunelleschi',
        'donatello':    networks_dir + 'donatello'
    }


# Don't give it a `save` name - that gets generated for you
jobs = [
        # {
        #     'no_load': True,
        # },
        # {
        #     'no_load': True,
        #     'force_invariance': True,
        #     'invariance_strength': 0.1
        # }
        # {
        #     'no_load': True,
        #     'force_invariance': True,
        #     'invariance_strength': 0.01
        # },
        # {
        #     'no_load': True,
        #     'force_invariance': True,
        #     'invariance_strength': 0.001
        # },
        # {
        #     'no_load': True,
        #     'force_invariance': True,
        #     'invariance_strength': 0.0001
        # },
        # {
        #     'import': 'brunelleschi',
        #     'force_invariance': True,
        #     'invariance_strength': 0.01,
        #     'shape_bias': True,
        #     'shape_bias_amount': 10

        # },
        # {
        #     'import': 'brunelleschi',
        #     'force_invariance': True,
        #     'invariance_strength': 0.01,
        #     'shape_bias': True,
        #     'shape_bias_amount': 40

        # },
        # {
        #     'import': 'brunelleschi',
        #     'force_invariance': True,
        #     'invariance_strength': 0.01,
        #     'shape_bias': True,
        #     'shape_bias_amount': 100

        # }
        {
            'import': 'donatello',
            'force_invariance': True,
            'invariance_strength': 0.01
        },
        {
            'import': 'donatello',
            'force_invariance': True,
            'invariance_strength': 0.001
        }
        # {
        #     'import': 'donatello',
        #     'shape_bias': True,
        #     'shape_bias_amount': 400,
        #     'learning_rate': -0.0002
        # }
    ]

for job in jobs:
    jobname = "invariance_scaled"
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
    flagstring = flagstring + " --save " + jobname


    with open('slurm_scripts/' + jobname + '.slurm', 'w') as slurmfile:
        slurmfile.write("#!/bin/bash\n")
        slurmfile.write("#SBATCH --job-name"+"=" + jobname + "\n")
        slurmfile.write("#SBATCH --output=slurm_logs/" + jobname + ".out\n")
        slurmfile.write("#SBATCH --error=slurm_logs/" + jobname + ".err\n")
        slurmfile.write("th monovariant_main.lua" + flagstring)

    # if not os.path.exists(jobname):
    #     os.makedirs(jobname)

    # with open(jobname + '/generating_parameters.txt', 'w') as paramfile:
    #     paramfile.write(str(job))

    print ("th monovariant_main.lua" + flagstring)
    if True:
        os.system("sbatch -N 1 -c 2 --gres=gpu:1 --time=6-23:00:00 slurm_scripts/" + jobname + ".slurm &")




