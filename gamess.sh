#!/bin/bash --login
#SBATCH --job-name=BN1_oxo_verdazyl_diradical-BHHLYP
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --nodes=1
#SBATCH --nodelist=wn29
#SBATCH --ntasks-per-node=16
#SBATCH --time=1-00:00:00
#SBATCH --mem=180G
#SBATCH --partition=cpu_guest
#SBATCH --qos=cpu_guest
#SBATCH --account=g_mmm

# --- CONFIGURAZIONE PATH ---
JOB_NAME=$SLURM_JOB_NAME
SUBMIT_DIR=$SLURM_SUBMIT_DIR
SCRATCH_BASE="/hpc/scratch/matteo.bedogni"
JOB_SCRATCH="${SCRATCH_BASE}/${JOB_NAME}_${SLURM_JOB_ID}"
# Cartella locale di destinazione (con input e output)
DEST_DIR="${SUBMIT_DIR}/calcolo_${JOB_NAME}"

# --- FUNZIONE DI PULIZIA E SPOSTAMENTO ---
function cleanup_all {
    echo "=========================================="
    echo "Fine calcolo. Spostamento file in corso..."
    
    # Crea la cartella di destinazione se non esiste
    mkdir -p "$DEST_DIR"

    # Copia l'input originale nella cartella finale
    cp "${SUBMIT_DIR}/${JOB_NAME}.inp" "$DEST_DIR/" 2>/dev/null

    # Sposta il file .out nella cartella finale
    if [ -f "${SUBMIT_DIR}/${JOB_NAME}.out" ]; then
        mv "${SUBMIT_DIR}/${JOB_NAME}.out" "$DEST_DIR/"
    fi

    # Sposta TUTTI i file generati in scratch (non la cartella stessa, solo il contenuto)
    # dentro la cartella di destinazione
    if [ -d "$JOB_SCRATCH" ]; then
        mv "${JOB_SCRATCH}/"* "$DEST_DIR/" 2>/dev/null
        
        # Ora cancella la cartella scratch vuota
        echo "Rimozoine cartella scratch: $JOB_SCRATCH"
        rm -rf "$JOB_SCRATCH"
    fi

    # Pulizia semafori
    USER_TRUNCATED=$(whoami | cut -c 1-10)
    ipcs -s | grep "$USER_TRUNCATED" | awk '{print $2}' | while read -r id; do
        ipcrm -s "$id"
    done

    echo "Operazione completata. Risultati in: $DEST_DIR"
    echo "=========================================="
}

trap cleanup_all EXIT

# Caricamento Moduli
module load gnu8 mpich
module load gamess

# Setup ambiente
mkdir -p "$JOB_SCRATCH"
cd "$JOB_SCRATCH"

# Copia input in scratch per GAMESS
cp "${SUBMIT_DIR}/${JOB_NAME}.inp" .

export USERSCR="$JOB_SCRATCH"
export SCRATCH="$JOB_SCRATCH"
unset SLURM_JOB_ID

# --- ESECUZIONE ---
# Genera il file .out direttamente nella cartella di sottomissione
# (che poi verrà spostato dalla funzione cleanup_all)
rungms-dev "${JOB_NAME}.inp" 00 "$SLURM_NTASKS" "$SLURM_NTASKS" > "${SUBMIT_DIR}/${JOB_NAME}.out"
