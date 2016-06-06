if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "./create_database <name of your keyspace>"
    exit 1
fi
python ./solr_dataloader.py $1

