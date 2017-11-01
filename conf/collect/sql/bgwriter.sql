SELECT
  now(),
  block_size::numeric * buffers_alloc / (1024 * 1024 * seconds) AS alloc_mbps,
  block_size::numeric * buffers_checkpoint / (1024 * 1024 * seconds) AS checkpoint_mbps,
  block_size::numeric * buffers_clean / (1024 * 1024 * seconds) AS clean_mbps,
  block_size::numeric * buffers_backend/ (1024 * 1024 * seconds) AS backend_mbps,
  block_size::numeric * (buffers_checkpoint + buffers_clean + buffers_backend) / (1024 * 1024 * seconds) AS write_mbps  
FROM
(
	SELECT now() AS sample,now() - stats_reset AS uptime,EXTRACT(EPOCH FROM now()) - extract(EPOCH FROM stats_reset) AS seconds, b.*,p.setting::integer AS block_size FROM pg_stat_bgwriter b,pg_settings p WHERE p.name='block_size'
) bgw
