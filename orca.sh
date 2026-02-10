#!/bin/bash
#SBATCH --job-name=orca
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --mem=50G
#SBATCH --time=00-12:00:00
#SBATCH --partition=cpu_guest
#SBATCH --account=g_mmm
#SBATCH --mail-type=ALL

# Verifica nome job
test -n "$SLURM_JOB_NAME" || exit 1

# Caricamento moduli
module load gnu8/8.3.0
module load openmpi4/4.1.1
module load orca/6.0.1

# Variabili
JOB_NAME="$SLURM_JOB_NAME"
SUBMIT_DIR="$SLURM_SUBMIT_DIR"
SCRATCH="/hpc/scratch/matteo.bedogni"
SCRATCH_DIR="${SCRATCH}/${JOB_NAME}_${SLURM_JOB_ID}"
LOCAL_DIR="${SUBMIT_DIR}/${JOB_NAME}_${SLURM_JOB_ID}_results"

mkdir -p "${SCRATCH_DIR}" || exit 1
mkdir -p "${LOCAL_DIR}"    || exit 1

# File input/output
INPUT_FILE="${JOB_NAME}.inp"
OUTPUT_FILE="${JOB_NAME}.out"
LOG_FILE="${JOB_NAME}.log"

# Copia file in scratch
cp "${SUBMIT_DIR}/${INPUT_FILE}" "${SCRATCH_DIR}/"
cp "${SUBMIT_DIR}"/*.gbw "${SCRATCH_DIR}/" 2>/dev/null || true
cp "${SUBMIT_DIR}"/*.chk "${SCRATCH_DIR}/" 2>/dev/null || true

# Vai in scratch
cd "${SCRATCH_DIR}" || exit 1

# Log iniziale
{
  echo "Job execution start: $(date)"
  echo "Job ID: ${SLURM_JOB_ID}"
  echo "Running on node(s): ${SLURM_JOB_NODELIST}"
  echo "Shared library path: $LD_LIBRARY_PATH"
} > "$LOG_FILE"

# Numero CPU
CPUS="${SLURM_NTASKS}"

# Lancia ORCA
$(which orca) "${INPUT_FILE}" > "${OUTPUT_FILE}" 2>> "${LOG_FILE}"

# Esegui orca_2mkl (necessita dei file generati da ORCA in SCRATCH)
if ls *.gbw 1> /dev/null 2>&1; then
    GBW_FILE=$(ls *.gbw | head -n 1)
    $(which orca_2mkl) "${GBW_FILE%.gbw}" -molden
fi

# Copia tutti i risultati in locale
cp -r "${SCRATCH_DIR}/"* "${LOCAL_DIR}/" 2>/dev/null || true

# Log finale (scritto nella cartella locale)
echo "Job execution end: $(date)" >> "${LOCAL_DIR}/${LOG_FILE}"

## PULIZIA: Rimuovi la cartella di scratch
echo "Pulizia cartella scratch: ${SCRATCH_DIR}" >> "${LOCAL_DIR}/${LOG_FILE}"
rm -rf "${SCRATCH_DIR}"
