#!/usr/bin/env python3
"""Submit a Nextflow pipeline"""

import os
import sys
import argparse
import subprocess

PARTITION_TYPES = ['F2', 'F32', 'F72', 'M64']
SCRATCH_SPACE = '/scratch'

def execute_sbatch_command(submission_command):
    """
    Submits the pipeline run via the sbatch command
    Parameters
    ----------
    submission_command : str
        The sbatch command to the scheduler that will submit your pipeline run
    """

    try:
        print('submitting pipeline: {submission_command}'
            .format(submission_command=submission_command))

        # try submitting to given scheduler
        with subprocess.Popen(submission_command, shell=True, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE) as process:
            submission_command_stdout, submission_command_sterr = process.communicate()

            # if scheduler command fails (exit code is not 0)
            if process.returncode != 0:
                raise OSError('error when submitting \n' \
                    '{submission_command_stdout}\n' \
                    '{submission_command_sterr}' \
                        .format(submission_command_stdout=submission_command_stdout,
                            submission_command_sterr=submission_command_sterr))

            print('{submission_command_stdout}'
                .format(submission_command_stdout=submission_command_stdout))

    # if subproccess itself fails
    except subprocess.CalledProcessError as error:
        print('error before submission: {error}\n' \
            'submission command stdout: {stdout}\n' \
            'submission command sterr: {sterr}'.format(error=error,
                stdout=error.stdout,
                sterr=error.stderr))


# generate sbatch command to be submmitted to Slurm
def generate_sbatch_command(nextflow_run_command, pipeline_run_name, partition_type, email=None):
    """
    Generate the sbatch command to submit your pipeline run.

    Parameters
    ----------
    nextflow_run_command : str
        The nextflow command to run the pipeline
    pipeline_run_name : str
        The name of your pipeline run.
    partition_type : str
        The partition type of the worker node your pipeline is to run on
    email : str [optional]
        The email that will receive status updates of your pipeline run

    Returns
    -------
    sbatch_command : string
        The sbatch command to Slurm that will submit your pipeline run
    """

    # what system call will be made to Slurm
    sbatch_command = 'sbatch ' \
        '--exclusive ' \
        '--partition={partition_type} ' \
        '-J {pipeline_run_name} ' \
        '-e {pipeline_run_name}.error ' \
        '-o {pipeline_run_name}.log ' \
        '--wrap="TEMP_DIR=$(mktemp -d {SCRATCH_SPACE}/XXXXXXX) && ' \
            'cd $TEMP_DIR && ' \
            '{nextflow_run_command}"' \
    .format(partition_type=partition_type,
        pipeline_run_name=pipeline_run_name,
        nextflow_run_command=nextflow_run_command,
        SCRATCH_SPACE=SCRATCH_SPACE)

    # add an email if provided
    if email:
        sbatch_command += ' --mail-user={email} --mail-type=ALL'.format(email=email)

    return sbatch_command


def generate_qsub_command(nextflow_run_command,
    pipeline_run_name,
    partition_type,
    smp_slots,
    email=None):
    """
    Generate the sbatch command to submit your pipeline run.

    Parameters
    ----------
    nextflow_run_command : str
        The nextflow command to run the pipeline
    pipeline_run_name : str
        The name of your pipeline run.
    partition_type : str
        The partition type of the worker node your pipeline is to run on
    smp_slots : int
        The number of slots used for -pe smpslots option used when submitting via qsub
    email : str [optional]
        The email that will receive status updates of your pipeline run

    Returns
    -------
    qsub_command : string
        The qsub command to SGE that will submit your pipeline run
    """

    # installing Nextflow and its dependicies
    install_requirements_command = generate_install_requirements_command()

    # what system call will be made to SGE
    qsub_command = 'sudo echo ' \
        '"TEMP_DIR=$(sudo mktemp -d {SCRATCH_SPACE}/XXXXXXX) && ' \
        'sudo cd $TEMP_DIR && ' \
        'sudo {install_requirements_command} && ' \
        'sudo ./{nextflow_run_command}" | ' \
        'qsub ' \
        '-S /bin/bash ' \
        '-l slot_type={partition_type} ' \
        '-cwd ' \
        '-N {pipeline_run_name} ' \
        '-e {pipeline_run_name}.error ' \
        '-o {pipeline_run_name}.log ' \
        '-pe smpslots {smp_slots} ' \
        .format(partition_type=partition_type,
            pipeline_run_name=pipeline_run_name,
            smp_slots=smp_slots,
            install_requirements_command=install_requirements_command,
            nextflow_run_command=nextflow_run_command,
            SCRATCH_SPACE=SCRATCH_SPACE)


    # add an email if provided
    if email:
        qsub_command += ' -M {email} -m abe'.format(email=email)

    return qsub_command


def generate_install_requirements_command():
    """
    Generate a command to install nextflow and its dependencies

    Returns
    -------
    install_requirements_command : str
        The shell command(s) to install Nextflow and Java
    """

    # install Java (OpenJDK), wget which
    install_nextflow_dependencies_command = 'sudo yum -y install ' \
        'java-1.8.0-openjdk ' \
        'wget ' \
        'which && ' \
        'sudo yum -y clean all'

    # install Nextflow (OpenJDK)
    nextflow_url = 'https://github.com/nextflow-io/nextflow/releases/download' + \
        '/v20.10.0/nextflow-20.10.0-all'

    install_nextflow_command = 'sudo wget -qO- ' \
        '{nextflow_url} ' \
        '| bash'.format(nextflow_url=nextflow_url)

    install_requirements_command = '{install_nextflow_dependencies_command} ' \
        '&& {install_nextflow_command}'.format(
            install_nextflow_dependencies_command=install_nextflow_dependencies_command,
            install_nextflow_command=install_nextflow_command)

    return install_requirements_command


# Command to run a nextflow executor on the submitting node (multi node use)
def generate_slurm_multi_node_nextflow_run_command(
    nextflow_run_command,
    pipeline_run_name,
    email=None):
    """
    Generate the nextflow command to run the pipeline with multi node use on Slurm

    Parameters
    ----------
    nextflow_run_command : str
        The nextflow command to run the pipeline
    pipeline_run_name : str
        The name of your pipeline run.
    email : str [optional]
        The email that will receive status updates of your pipeline run

    Returns
    -------
    slurm_multi_node_nextflow_run_command : str
        The command to run the pipeline
    """

    # run in background
    slurm_multi_node_nextflow_run_command = nextflow_run_command + ' -bg'

    if email:
        slurm_multi_node_nextflow_run_command += ' -with-notification {email}'.format(email=email)

    # capture both stdout and error
    slurm_multi_node_nextflow_run_command += ' > {pipeline_run_name}.log ' \
        '2> {pipeline_run_name}.error'.format(pipeline_run_name=pipeline_run_name)

    return slurm_multi_node_nextflow_run_command


# use nextflow CLI nextflow run to run the pipeline with a .nf and .config file
def generate_nextflow_run_command(nextflow_script, nextflow_config=None):
    """
    Generate the nextflow command to run the pipeline
    Parameters
    ----------
    nextflow_script : str
        The path for the pipeline script/.nf file
    nextflow_config : str [optional]
        The path for the pipeline config/.config file

    Returns
    -------
    nextflow_run_command : str
        The nextflow command to run the pipeline
    """

    nextflow_run_command = 'nextflow run {nextflow_script}' \
    .format(nextflow_script=nextflow_script)

    # add a configuration file if given
    if nextflow_config:
        nextflow_run_command += ' -config {nextflow_config}'.format(nextflow_config=nextflow_config)

    return nextflow_run_command


# submit the pipeline using the generated sbatch command
def submit_pipeline_run(args):
    """
    Submits the pipeline run via the sbatch command.

    Parameters
    ----------
    args : argparse.Namespace
        The inputs/options for submitting a pipeline
    """

    scheduler_command = ""
    nextflow_run_command = generate_nextflow_run_command(args.nextflow_script, args.nextflow_config)

    if args.multi_node_mode:
        # make sure pipeline is run in background mode
        scheduler_command = generate_slurm_multi_node_nextflow_run_command(
            nextflow_run_command,
            args.pipeline_run_name,
            args.email)

    # if single node use
    else:
        # create command with qsub to submit to SGE
        if args.sge_scheduler:
            scheduler_command = generate_qsub_command(
                nextflow_run_command,
                args.pipeline_run_name,
                args.partition_type,
                args.smp_slots,
                args.email)

        # create command with sbatch to submit to Slurm
        else:
            scheduler_command = generate_sbatch_command(
                nextflow_run_command,
                args.pipeline_run_name,
                args.partition_type,
                args.email)
    execute_sbatch_command(scheduler_command)


# input that should be present depending on if you are using SGE or Slurm
def validate_required_inputs(input_options, submission_type):
    """
    Validates that inputs are specified given the particular scheduluer

    Parameters
    ----------
    input_options : dict
        The dictionary of input options to validate, e.g ({input_option_name: input_option_value})
    submission_type : str
        The submission type being used
    """

    required_input_error_message = 'Missing {input_option}, ' \
        'option is required when submitting to {submission_type}'

    # if an input option is not given when it should be
    for input_option in input_options:
        if input_options[input_option] is None:
            raise argparse.ArgumentTypeError(required_input_error_message
                .format(input_option=input_option,
                    submission_type=submission_type))


# input that should be missing depending on if you are using SGE or Slurm
def validate_missing_inputs(input_options, submission_type):
    """
    Validates that inputs are not specified given the particular scheduluer

    Parameters
    ----------
    input_options : dict
        The dictionary of input options to validate, e.g ({input_option_name: input_option_value})
    submission_type : str
        The submission type being used
    """

    missing_input_error_message = 'Invalid option, {input_option}, ' \
        'option should not be used when submitting via {submission_type}'

    # if an input option is given when it shouldn't be
    for input_option in input_options:
        if input_options[input_option]:
            raise argparse.ArgumentTypeError(missing_input_error_message
                .format(input_option=input_option,
                    submission_type=submission_type))


# validates input combination for Slurm vs SGE
def validate_input_combinations(
    multi_node_mode,
    sge_scheduler,
    partition_type=None,
    smp_slots=None):
    """
    Validates that the user has submitted the correct combination inputs

    Parameters
    ----------
    multi_node_mode : bool
        If the pipeline is to be run on multi node mode
    sge_scheduler : bool
        If the SGE scheduler is used to submit the pipeline run
    partition_type : str (optional)
        The partition type of the worker node your pipeline is to run on

    smp_slots : int (optional)
        The number of slots used for -pe smpslots option used when submitting via qsub
    """

    if multi_node_mode:
        multi_node_invalid_input_options = {
            'partition_type': partition_type,
            'smp_slots': smp_slots,
            'sge_scheduler': sge_scheduler}

        validate_missing_inputs(multi_node_invalid_input_options, 'multi node mode')


    # if single node use
    else:
        # if submitting to SGE
        if sge_scheduler:
            single_node_required_sge_input_options = {
                'partition type': partition_type,
                'smp_slots': smp_slots}
            validate_required_inputs(single_node_required_sge_input_options, 'SGE')

        # if submitting to Slurm
        else:
            single_node_invalid_slurm_input_options = {
                'smp_slots': smp_slots,
                'sge_scheduler': sge_scheduler
                }
            single_node_required_slurm_input_options = {'partition type': partition_type}
            validate_missing_inputs(single_node_invalid_slurm_input_options, 'Slurm')
            validate_required_inputs(single_node_required_slurm_input_options, 'Slurm')


# validates the partition type
def validate_smp_slots(smp_slots):
    """
    Validates that the smp_slots is compatiable with the SGE configuration.

    Parameters
    ----------
    smp_slots : int
        The number of slots used for -pe smpslots option used when submitting via qsub

    Returns
    -------
    smp_slots : int
        The number of slots used for -pe smpslots option used when submitting via qsub
    """

    # if smp_slots is specifiec by the user it check if it is an in greater than 0
    if smp_slots is not None:
        # enfore type int
        smp_slots = int(smp_slots)

        if not isinstance(smp_slots, int) or smp_slots < 1:
            raise argparse.ArgumentTypeError(
                'Invalid smp_slots: {smp_slots}, smp_slots must be an integer greater than 0'
                .format(smp_slots=smp_slots))

    return smp_slots


# validates the partition type
def validate_partition_type(partition_type):
    """
    Validates that the partition type is compatiable with the Slurm configurations.

    Parameters
    ----------
    partition_type : str
        The absolute path for the pipeline script or config file

    Returns
    -------
    partition_type : str
        The absolute path for the pipeline script or config file
    """

    # if partition type is specifiec by the user it check if it valid partition name
    if partition_type and partition_type not in PARTITION_TYPES:
        raise argparse.ArgumentTypeError(
            'Invalid partition type: {partition_type}, ' \
                'partition type must be one of the following: {PARTITION_TYPES}'
            .format(partition_type=partition_type, PARTITION_TYPES=PARTITION_TYPES))

    return partition_type


# raises an error when the path is not an file path
def validate_path(file_path):
    """
    Validates that a given path is a file.

    Parameters
    ----------
    file_path : str
        The absolute path for the pipeline script or config file

    Returns
    -------
    file_path : str
        The absolute path for the pipeline script or config file
    """

    # check if input file is a valid file path
    if not os.path.isfile(file_path):
        raise argparse.ArgumentTypeError(
            'Invalid file path: {file_path}, ' \
                'Please enter a valid path to your file'.format(file_path=file_path))

    return file_path


# validate True/False flags
def validate_flag(flag):
    """
    Validates that a given path is a file.

    Parameters
    ----------
    flag : str/bool

        Validate True/False flags specififed by the user

    Returns
    -------
    flag : bool
        Validate True/False flags specififed by the user
    """

    # check if flag is not True or False
    if not isinstance(flag, bool):
        if (flag not in ['True', 'False']):
            raise argparse.ArgumentTypeError(
                'Invalid flag(T/F): {flag}, ' \
                    'Please enter either True or False'.format(flag=flag))

        flag = flag == 'True'

    return flag


# gets the inputs required to run a nextflow pipeline
def get_pipeline_run_inputs():
    """
    Command line entrypoint for submitting nextflow pipelines for SINGLE-NODE use.

    Returns
    -------
    args : argparse.Namespace
        arguments list, The default value of None, when passed to `parser.parse_args`
        causes the parser to read `sys.argv`
    """

    # get inputs/arguments
    parser = argparse.ArgumentParser()

    # which scheduler/mode to use
    parser.add_argument(
        '--sge_scheduler',
        dest='sge_scheduler',
        required=False,
        default=False,
        type=validate_flag,
        help='If True, it attempts to submit the pipeline run to the SGE scheduler is used '\
            '(optional). Default=False')
    parser.add_argument(
        '-m',
        '--multi_node_mode',
        dest='multi_node_mode',
        required=False,
        default=False,
        type=validate_flag,
        help='If True, it will run the pipeline in multi node mode, ' \
            'using a Nextflow exectuor to monitor and manage the pipeline in background '\
            'from THE NODE THE PIPELINE WAS SUBMITTED FROM (optional). Default=False. ' \
            '\n***FOR SLURM USE ONLY***\n' \
            '\n***PLEASE NOTE: MULTI NODE USE MUST BE ENABLED IN YOUR CONFIG FILE***\n')

    # nextflow options
    parser.add_argument(
        '-n',
        '--nextflow_script',
        dest='nextflow_script',
        required=True,
        type=validate_path,
        help='The absolute path for the pipeline script/.nf file')
    parser.add_argument(
        '-C',
        '--nextflow_config',
        dest='nextflow_config',
        required=False,
        type=validate_path,
        help='The absolute path for the pipeline config/.config file (optional)')
    parser.add_argument(
        '-p',
        '--pipeline_run_name',
        dest='pipeline_run_name',
        required=True,
        help='The name of your pipeline run')
    parser.add_argument(
        '-t',
        '--partition_type',
        dest='partition_type',
        required=False,
        default=None,
        type=validate_partition_type,
        help='The partition type your pipeline is to run on: {partition_types}. ' \
            '\n***FOR SLURM USE ONLY***\n'
        .format(partition_types=PARTITION_TYPES))

    # SGE options
    parser.add_argument(
        '-s',
        '--smp_slots',
        dest='smp_slots',
        required=False,
        default=None,
        type=validate_smp_slots,
        help='The number of slots used for -pe smpslots option used when submitting via qsub. ' \
            '\n***FOR SGE USE ONLY***\n')

    # Generic scheduler options (applies to both SGE and Slurm)
    parser.add_argument(
        '-e',
        '--email',
        dest='email',
        required=False,
        default=None,
        help='The email that will receive status updates of your pipeline run (optional)')

    args = parser.parse_args()
    validate_input_combinations(
        args.multi_node_mode,
        args.sge_scheduler,
        args.partition_type,
        args.smp_slots)

    return args


# validate and execute the pipeline
if __name__ == '__main__':
    ARGS = get_pipeline_run_inputs()
    sys.exit(submit_pipeline_run(ARGS))
