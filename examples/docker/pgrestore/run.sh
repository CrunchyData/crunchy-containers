
dockes required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "starting restore container..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$DIR"/cleanup.sh

CONTAINER_NAME=pgrestore
VOLUME_NAME=$CONTAINER_NAME-volume
VOLUME_PATH=/pgrestore
RESTORE_FROM_DIR=/tmp/
RESTORE_FROM_FILE=pgdumpall.sql
RESTORE_FULLPATH=$(realpath -s "$RESTORE_FROM_DIR")"/$RESTORE_FROM_FILE"

#
# this example assumes you have the basic example running
#
HOST_TO_RESTORE=basic

docker volume create --driver local --name=$VOLUME_NAME

docker create \
        --privileged=true \
        -v "$VOLUME_NAME":"$VOLUME_PATH" \
        -e PGRESTORE_HOST="$HOST_TO_RESTORE" \
        -e PGRESTORE_DB=postgres \
        -e PGRESTORE_USER=postgres \
        -e PGRESTORE_PASS=password \
        -e PGRESTORE_PORT=5432 \
        -e PGRESTORE_LABEL=myrestore \
        -e PGRESTORE_FILE="$RESTORE_FROM_FILE" \
	-e PGRESTORE_VOLUMEPATH=$VOLUME_PATH \
        -e PGRESTORE_FORMAT=t \
        --link "$HOST_TO_RESTORE":"$HOST_TO_RESTORE"\
        --name="$CONTAINER_NAME" \
        --hostname="$CONTAINER_NAME" \
        "$CCP_IMAGE_PREFIX/crunchy-restore:$CCP_IMAGE_TAG"

echo "Copying files to container with the command: docker cp $RESTORE_FULLPATH $CONTAINER_NAME:$VOLUME_PATH"
docker cp "$RESTORE_FULLPATH" "$CONTAINER_NAME":"$VOLUME_PATH"

docker start "$CONTAINER_NAME"
